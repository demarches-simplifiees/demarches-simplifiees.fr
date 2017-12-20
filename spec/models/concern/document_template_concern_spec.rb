describe AttestationTemplate, type: :model do
  let(:types_de_champ) { [] }
  let(:types_de_champ_private) { [] }
  let(:for_individual) { false }

  let(:procedure) do
    create(:procedure,
      libelle: 'Une magnifique procédure',
      types_de_champ: types_de_champ,
      types_de_champ_private: types_de_champ_private,
      for_individual: for_individual)
  end

  let(:template_concern) do
    (Class.new do
      include DocumentTemplateConcern
      public :replace_tags

      def initialize(p)
        @procedure = p
      end

      def procedure
        @procedure
      end
    end).new(procedure)
  end

  describe 'replace_tags' do
    let(:individual) { nil }
    let(:etablissement) { nil }
    let(:entreprise) { create(:entreprise, etablissement: etablissement) }
    let!(:dossier) { create(:dossier, procedure: procedure, individual: individual, entreprise: entreprise) }

    before { Timecop.freeze(Time.now) }

    subject { template_concern.replace_tags(template, dossier) }

    after { Timecop.return }

    context 'when the dossier and the procedure has an individual' do
      let(:for_individual) { true }
      let(:individual) { Individual.create(nom: 'nom', prenom: 'prenom', gender: 'Mme') }

      context 'and the template use the individual tags' do
        let(:template) { '--civilité-- --nom-- --prénom--' }

        it { is_expected.to eq('Mme nom prenom') }
      end
    end

    context 'when the dossier and the procedure has an entreprise' do
      let(:for_individual) { false }

      context 'and the template use the entreprise tags' do
        let(:template) do
          '--SIREN-- --numéro de TVA intracommunautaire-- --SIRET du siège social-- --raison sociale-- --adresse--'
        end

        let(:extected_text) do
          "#{entreprise.siren} #{entreprise.numero_tva_intracommunautaire} #{entreprise.siret_siege_social} #{entreprise.raison_sociale} --adresse--"
        end

        it { is_expected.to eq(extected_text) }

        context 'and the entreprise has a etablissement with an adresse' do
          let(:etablissement) { create(:etablissement, adresse: 'adresse') }
          let(:template) { '--adresse--' }

          it { is_expected.to eq(etablissement.inline_adresse) }
        end
      end
    end

    context 'when the procedure has a type de champ named libelleA et libelleB' do
      let(:types_de_champ) do
        [create(:type_de_champ_public, libelle: 'libelleA'),
         create(:type_de_champ_public, libelle: 'libelleB')]
      end

      context 'and the template is nil' do
        let(:template) { nil }

        it { is_expected.to eq('') }
      end

      context 'and it is not used in the template' do
        let(:template) { '' }
        it { is_expected.to eq('') }
      end

      context 'and they are used in the template' do
        let(:template) { '--libelleA-- --libelleB--' }

        context 'and their value in the dossier are nil' do
          it { is_expected.to eq(' ') }
        end

        context 'and their value in the dossier are not nil' do
          before do
            dossier.champs
              .select { |champ| champ.libelle == 'libelleA' }
              .first
              .update_attributes(value: 'libelle1')

            dossier.champs
              .select { |champ| champ.libelle == 'libelleB' }
              .first
              .update_attributes(value: 'libelle2')
          end

          it { is_expected.to eq('libelle1 libelle2') }
        end
      end
    end

    context 'when the dossier has a motivation' do
      let(:dossier) { create(:dossier, motivation: 'motivation') }

      context 'and the template has some dossier tags' do
        let(:template) { '--motivation-- --numéro du dossier--' }

        it { is_expected.to eq("motivation #{dossier.id}") }
      end
    end

    context 'when the procedure has a type de champ prive named libelleA' do
      let(:types_de_champ_private) { [create(:type_de_champ_private, libelle: 'libelleA')] }

      context 'and the are used in the template' do
        let(:template) { '--libelleA--' }

        context 'and its value in the dossier are not nil' do
          before { dossier.champs_private.first.update_attributes(value: 'libelle1') }

          it { is_expected.to eq('libelle1') }
        end
      end
    end

    context 'when the procedure has 2 types de champ date and datetime' do
      let(:types_de_champ) do
        [create(:type_de_champ_public, libelle: 'date', type_champ: 'date'),
         create(:type_de_champ_public, libelle: 'datetime', type_champ: 'datetime')]
      end

      context 'and the are used in the template' do
        let(:template) { '--date-- --datetime--' }

        context 'and its value in the dossier are not nil' do
          before do
            dossier.champs
              .select { |champ| champ.type_champ == 'date' }
              .first
              .update_attributes(value: '2017-04-15')

            dossier.champs
              .select { |champ| champ.type_champ == 'datetime' }
              .first
              .update_attributes(value: '13/09/2017 09:00')
          end

          it { is_expected.to eq('15/04/2017 13/09/2017 09:00') }
        end
      end
    end

    context "when the template has a libellé procédure tag" do
      let(:template) { '--libelle_procedure--' }

      it { is_expected.to eq('Une magnifique procédure') }
    end

    context "when the template has a date de décision tag" do
      let(:template) { '--date_de_decision--' }

      context "and the dossier has a date de décision" do
        let!(:dossier) { create(:dossier, processed_at: DateTime.new(2005, 3, 12), procedure: procedure, individual: individual, entreprise: entreprise) }

        it { is_expected.to eq('12/03/2005') }
      end

      context "and the dossier has no date de décision" do
        it { is_expected.to eq('') }
      end
    end

    context "when the template has a lien_dossier tag" do
      let(:template) { '--lien_dossier--' }

      it { is_expected.to include("/users/dossiers/#{dossier.id}/recapitulatif") }
    end

    context "match breaking and non breaking spaces" do
      before { dossier.champs.first.update_attributes(value: 'valeur') }

      shared_examples "treat all kinds of space as equivalent" do
        context 'and the champ has a non breaking space' do
          let(:types_de_champ) { [create(:type_de_champ_public, libelle: 'mon tag')] }

          it { is_expected.to eq('valeur') }
        end

        context 'and the champ has an ordinary space' do
          let(:types_de_champ) { [create(:type_de_champ_public, libelle: 'mon tag')] }

          it { is_expected.to eq('valeur') }
        end
      end

      context "when the tag has a non breaking space" do
        let(:template) { '--mon tag--' }

        it_behaves_like "treat all kinds of space as equivalent"
      end

      context "when the tag has an ordinary space" do
        let(:template) { '--mon tag--' }

        it_behaves_like "treat all kinds of space as equivalent"
      end
    end

    context 'when generating a document for a dossier before closing it' do
      let(:dossier) { create(:dossier) }
      let(:template) { '--motivation-- --date de décision--' }

      subject { template_concern.replace_tags(template, dossier, for_closed_dossier: false) }

      it "does not treat motivation and date de decision as tags" do
        is_expected.to eq('--motivation-- --date de décision--')
      end
    end
  end

  describe 'tags' do
    context 'when generating an attestation for a closed dossier' do
      subject { template_concern.tags }

      it { is_expected.to include(include({ libelle: 'motivation' })) }
      it { is_expected.to include(include({ libelle: 'date_de_decision' })) }
    end

    context 'when generating an attestation for a dossier that is still open' do
      subject { template_concern.tags(for_closed_dossier: false) }

      it { is_expected.not_to include(include({ libelle: 'motivation' })) }
      it { is_expected.not_to include(include({ libelle: 'date_de_decision' })) }
    end
  end
end
