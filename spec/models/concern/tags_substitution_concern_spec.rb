describe TagsSubstitutionConcern, type: :model do
  let(:types_de_champ) { [] }
  let(:types_de_champ_private) { [] }
  let(:for_individual) { false }
  let(:state) { Dossier.states.fetch(:accepte) }

  let(:service) { create(:service, nom: 'Service instructeur') }

  let(:procedure) do
    create(:procedure,
      libelle: 'Une magnifique démarche',
      types_de_champ: types_de_champ,
      types_de_champ_private: types_de_champ_private,
      for_individual: for_individual,
      service: service,
      organisation: nil)
  end

  let(:template_concern) do
    (Class.new do
      include TagsSubstitutionConcern

      def initialize(p, s)
        @procedure = p
        self.class.const_set(:DOSSIER_STATE, s)
      end

      def procedure
        @procedure
      end
    end).new(procedure, state)
  end

  describe 'replace_tags' do
    let(:individual) { nil }
    let(:etablissement) { create(:etablissement) }
    let!(:dossier) { create(:dossier, procedure: procedure, individual: individual, etablissement: etablissement) }

    before { Timecop.freeze(Time.zone.now) }

    subject { template_concern.send(:replace_tags, template, dossier) }

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
        let(:etablissement) { create(:etablissement) }

        let(:expected_text) do
          "#{etablissement.entreprise_siren} #{etablissement.entreprise_numero_tva_intracommunautaire} #{etablissement.entreprise_siret_siege_social} #{etablissement.entreprise_raison_sociale} #{etablissement.inline_adresse}"
        end

        it { is_expected.to eq(expected_text) }
      end
    end

    context 'when the procedure has a type de champ named libelleA et libelleB' do
      let(:types_de_champ) do
        [
          create(:type_de_champ, libelle: 'libelleA'),
          create(:type_de_champ, libelle: 'libelleB')
        ]
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
              .update(value: 'libelle1')

            dossier.champs
              .select { |champ| champ.libelle == 'libelleB' }
              .first
              .update(value: 'libelle2')
          end

          it { is_expected.to eq('libelle1 libelle2') }
        end
      end
    end

    context 'when the procedure has a linked drop down menus type de champ' do
      let(:type_de_champ) do
        create(:type_de_champ_linked_drop_down_list, libelle: 'libelle')
      end
      let(:types_de_champ) { [type_de_champ] }
      let(:template) { 'tout : --libelle--, primaire : --libelle/primaire--, secondaire : --libelle/secondaire--' }

      context 'and the champ has no value' do
        it { is_expected.to eq('tout : , primaire : , secondaire : ') }
      end

      context 'and the champ has a primary value' do
        before do
          dossier.champs.find_by(type_de_champ: type_de_champ).update(primary_value: 'primo')
          dossier.reload
        end

        it { is_expected.to eq('tout : primo, primaire : primo, secondaire : ') }

        context 'and the champ has a secondary value' do
          before do
            dossier.champs.find_by(type_de_champ: type_de_champ).update(secondary_value: 'secundo')
            dossier.reload
          end

          it { is_expected.to eq('tout : primo / secundo, primaire : primo, secondaire : secundo') }

          context 'and the same libelle is used by a header' do
            let(:types_de_champ) do
              [
                type_de_champ,
                create(:type_de_champ_header_section, libelle: 'libelle')
              ]
            end

            it { is_expected.to eq('tout : primo / secundo, primaire : primo, secondaire : secundo') }
          end
        end
      end
    end

    context 'when the user requests the service' do
      let(:template) { 'Dossier traité par --nom du service--' }

      context 'and there is a service' do
        it { is_expected.to eq("Dossier traité par #{service.nom}") }
      end

      context 'and there is no service yet' do
        let(:service) { nil }
        it { is_expected.to eq("Dossier traité par ") }
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
      let(:types_de_champ_private) { [create(:type_de_champ, :private, libelle: 'libelleA')] }

      context 'and it is used in the template' do
        let(:template) { '--libelleA--' }

        context 'and its value in the dossier is not nil' do
          before { dossier.champs_private.first.update(value: 'libelle1') }

          it { is_expected.to eq('libelle1') }
        end
      end
    end

    context 'when the dossier is en construction' do
      let(:state) { Dossier.states.fetch(:en_construction) }
      let(:template) { '--libelleA--' }

      context 'champs privés are not valid tags' do
        # The dossier just transitionned from brouillon to en construction,
        # so champs private are not valid tags yet

        let(:types_de_champ_private) { [create(:type_de_champ, :private, libelle: 'libelleA')] }

        it { is_expected.to eq('--libelleA--') }
      end

      context 'champs publics are valid tags' do
        let(:types_de_champ) { [create(:type_de_champ, libelle: 'libelleA')] }

        before { dossier.champs.first.update(value: 'libelle1') }

        it { is_expected.to eq('libelle1') }
      end
    end

    context 'when the procedure has 2 types de champ date and datetime' do
      let(:types_de_champ) do
        [
          create(:type_de_champ_date, libelle: TypeDeChamp.type_champs.fetch(:date)),
          create(:type_de_champ_datetime, libelle: TypeDeChamp.type_champs.fetch(:datetime))
        ]
      end

      context 'and the are used in the template' do
        let(:template) { '--date-- --datetime--' }

        context 'and its value in the dossier are not nil' do
          before do
            dossier.champs
              .select { |champ| champ.type_champ == TypeDeChamp.type_champs.fetch(:date) }
              .first
              .update(value: '2017-04-15')

            dossier.champs
              .select { |champ| champ.type_champ == TypeDeChamp.type_champs.fetch(:datetime) }
              .first
              .update(value: '2017-09-13 09:00')
          end

          it { is_expected.to eq('15/04/2017 2017-09-13 09:00') }
        end
      end
    end

    context "when using a date tag" do
      before do
        dossier.en_construction_at = Time.zone.local(2001, 2, 3)
        dossier.en_instruction_at = Time.zone.local(2004, 5, 6)
        dossier.processed_at = Time.zone.local(2007, 8, 9)
      end

      context "with date de dépôt" do
        let(:template) { '--date de dépôt--' }

        it { is_expected.to eq('03/02/2001') }
      end

      context "with date de passage en instruction" do
        let(:template) { '--date de passage en instruction--' }

        it { is_expected.to eq('06/05/2004') }
      end

      context "with date de décision" do
        let(:template) { '--date de décision--' }

        it { is_expected.to eq('09/08/2007') }
      end
    end

    context "when the template has a libellé démarche tag" do
      let(:template) { 'body --libellé démarche--' }

      it { is_expected.to eq('body Une magnifique démarche') }
    end

    context "match breaking and non breaking spaces" do
      before { dossier.champs.first.update(value: 'valeur') }

      shared_examples "treat all kinds of space as equivalent" do
        context 'and the champ has a non breaking space' do
          let(:types_de_champ) { [create(:type_de_champ, libelle: 'mon tag')] }

          it { is_expected.to eq('valeur') }
        end

        context 'and the champ has an ordinary space' do
          let(:types_de_champ) { [create(:type_de_champ, libelle: 'mon tag')] }

          it { is_expected.to eq('valeur') }
        end
      end

      context "when the tag has a non breaking space" do
        let(:template) { '--mon tag--' }

        it_behaves_like "treat all kinds of space as equivalent"
      end

      context "when the tag has an ordinary space" do
        let(:template) { '--mon tag--' }

        it_behaves_like "treat all kinds of space as equivalent"
      end
    end

    context 'when generating a document for a dossier that is not termine' do
      let(:dossier) { create(:dossier) }
      let(:template) { '--motivation-- --date de décision--' }
      let(:state) { Dossier.states.fetch(:en_instruction) }

      subject { template_concern.send(:replace_tags, template, dossier) }

      it "does not treat motivation or date de décision as tags" do
        is_expected.to eq('--motivation-- --date de décision--')
      end
    end
  end

  describe 'tags' do
    subject { template_concern.tags }

    let(:types_de_champ) do
      [
        create(:type_de_champ, libelle: 'public'),
        create(:type_de_champ_header_section, libelle: 'entête de section'),
        create(:type_de_champ_explication, libelle: 'explication')
      ]
    end
    let(:types_de_champ_private) { [create(:type_de_champ, :private, libelle: 'privé')] }

    context 'do not generate tags for champs that cannot have usager content' do
      it { is_expected.not_to include(include({ libelle: 'entête de section' })) }
      it { is_expected.not_to include(include({ libelle: 'explication' })) }
    end

    context 'when generating a document for a dossier terminé' do
      it { is_expected.to include(include({ libelle: 'motivation' })) }
      it { is_expected.to include(include({ libelle: 'date de décision' })) }
      it { is_expected.to include(include({ libelle: 'public' })) }
      it { is_expected.to include(include({ libelle: 'privé' })) }
    end

    context 'when generating a document for a dossier en instruction' do
      let(:state) { Dossier.states.fetch(:en_instruction) }

      it { is_expected.not_to include(include({ libelle: 'motivation' })) }
      it { is_expected.not_to include(include({ libelle: 'date de décision' })) }

      it { is_expected.to include(include({ libelle: 'public' })) }
      it { is_expected.to include(include({ libelle: 'privé' })) }
    end

    context 'when generating a document for a dossier en construction' do
      let(:state) { Dossier.states.fetch(:en_construction) }

      it { is_expected.not_to include(include({ libelle: 'motivation' })) }
      it { is_expected.not_to include(include({ libelle: 'date de décision' })) }
      it { is_expected.not_to include(include({ libelle: 'privé' })) }

      it { is_expected.to include(include({ libelle: 'public' })) }
    end
  end
end
