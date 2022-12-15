describe TagsSubstitutionConcern, type: :model do
  let(:types_de_champ_public) { [] }
  let(:types_de_champ_private) { [] }
  let(:for_individual) { false }
  let(:state) { Dossier.states.fetch(:accepte) }

  let(:service) { create(:service, nom: 'Service instructeur') }

  let(:procedure) do
    create(:procedure,
      :published,
      libelle: 'Une magnifique démarche',
      types_de_champ_public: types_de_champ_public,
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
    let(:instructeur) { create(:instructeur) }

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

    context 'when the template use the groupe instructeur tags' do
      let(:template) { '--groupe instructeur--' }
      let(:state) { Dossier.states.fetch(:en_instruction) }
      let!(:dossier) { create(:dossier, procedure: procedure, individual: individual, etablissement: etablissement, state: state) }
      context 'and the dossier has a groupe instructeur' do
        label = 'Ville de Bordeaux'
        before do
          gi = procedure.groupe_instructeurs.create(label: label)
          gi.dossiers << dossier
          dossier.update(groupe_instructeur: gi)
          dossier.reload
          procedure.reload
        end

        it { expect(procedure.routing_enabled?).to eq(true) }
        it { is_expected.to eq(label) }
      end

      context 'and the dossier has no groupe instructeur' do
        it { expect(procedure.routing_enabled?).to eq(false) }
        it { is_expected.to eq('défaut') }
      end
    end

    context 'when the procedure has a type de champ named libelleA et libelleB' do
      let(:types_de_champ_public) do
        [
          { libelle: 'libelleA' },
          { libelle: "libelle\xc2\xA0B".encode('utf-8') }
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
        let(:template) { '--libelleA-- --libelle B--' }

        context 'and their value in the dossier are nil' do
          it { is_expected.to eq(' ') }
        end

        context 'and their value in the dossier are not nil' do
          before do
            dossier.champs_public
              .find { |champ| champ.libelle == 'libelleA' }
              .update(value: 'libelle1')

            dossier.champs_public
              .find { |champ| champ.libelle == "libelle\xc2\xA0B".encode('utf-8') }
              .update(value: 'libelle2')
          end

          it { is_expected.to eq('libelle1 libelle2') }
        end
      end
    end

    context 'when the procedure has a type de champ with apostrophes' do
      let(:types_de_champ_public) do
        [
          { libelle: "Intitulé de l'‘«\"évènement\"»’" }
        ]
      end

      context 'and they are used in the template' do
        let(:template) { "--Intitulé de l'‘«\"évènement\"»’--" }

        context 'and their value in the dossier are not nil' do
          before do
            dossier.champs_public
              .find { |champ| champ.libelle == "Intitulé de l'‘«\"évènement\"»’" }
              .update(value: 'ceci est mon évènement')
          end

          it { is_expected.to eq('ceci est mon évènement') }
        end
      end
    end

    context 'when the procedure has a type de champ repetition' do
      let(:template) { '--Répétition--' }
      let(:repetition) do
        repetition_tdc = procedure.active_revision.add_type_de_champ(type_champ: 'repetition', libelle: 'Répétition')
        procedure.active_revision.add_type_de_champ(type_champ: 'text', libelle: 'Nom', parent_stable_id: repetition_tdc.stable_id)
        procedure.active_revision.add_type_de_champ(type_champ: 'text', libelle: 'Prénom', parent_stable_id: repetition_tdc.stable_id)

        repetition_tdc
      end

      let(:dossier) do
        repetition
        create(:dossier, procedure: procedure)
      end

      before do
        repetition = dossier.champs_public
          .find { |champ| champ.libelle == 'Répétition' }
        repetition.add_row(dossier.revision)
        paul_champs, pierre_champs = repetition.rows

        paul_champs.first.update(value: 'Paul')
        paul_champs.last.update(value: 'Chavard')

        pierre_champs.first.update(value: 'Pierre')
        pierre_champs.last.update(value: 'de La Morinerie')
      end

      it { is_expected.to eq("Répétition\n\nNom : Paul\nPrénom : Chavard\n\nNom : Pierre\nPrénom : de La Morinerie") }
    end

    context 'when the procedure has a linked drop down menus type de champ' do
      let(:type_de_champ) { procedure.draft_revision.types_de_champ.first }
      let(:types_de_champ_public) { [{ type: :linked_drop_down_list, libelle: 'libelle' }] }
      let(:template) { 'tout : --libelle--, primaire : --libelle/primaire--, secondaire : --libelle/secondaire--' }

      context 'and the champ has no value' do
        it { is_expected.to eq('tout : , primaire : , secondaire : ') }
      end

      context 'and the champ has a primary value' do
        before do
          dossier.champs_public.find_by(type_de_champ: type_de_champ).update(primary_value: 'primo')
          dossier.reload
        end

        it { is_expected.to eq('tout : primo, primaire : primo, secondaire : ') }

        context 'and the champ has a secondary value' do
          before do
            dossier.champs_public.find_by(type_de_champ: type_de_champ).update(secondary_value: 'secundo')
            dossier.reload
          end

          it { is_expected.to eq('tout : primo / secundo, primaire : primo, secondaire : secundo') }

          context 'and the same libelle is used by a header' do
            let(:types_de_champ_public) do
              [
                { type: :linked_drop_down_list, libelle: 'libelle' },
                { type: :header_section, libelle: 'libelle' }
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
      let(:dossier) { create(:dossier, :accepte, motivation: 'motivation') }

      context 'and the template has some dossier tags' do
        let(:template) { '--motivation-- --numéro du dossier--' }

        it { is_expected.to eq("motivation #{dossier.id}") }
      end
    end

    context 'when the procedure has a type de champ prive named libelleA' do
      let(:types_de_champ_private) { [{ libelle: 'libelleA' }] }

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

        let(:types_de_champ_private) { [{ libelle: 'libelleA' }] }

        it { is_expected.to eq('--libelleA--') }
      end

      context 'champs publics are valid tags' do
        let(:types_de_champ_public) { [{ libelle: 'libelleA' }] }

        before { dossier.champs_public.first.update(value: 'libelle1') }

        it { is_expected.to eq('libelle1') }
      end
    end

    context 'when the procedure has 2 types de champ date and datetime' do
      let(:types_de_champ_public) do
        [
          { type: :date, libelle: TypeDeChamp.type_champs.fetch(:date) },
          { type: :datetime, libelle: TypeDeChamp.type_champs.fetch(:datetime) }
        ]
      end

      context 'and the are used in the template' do
        let(:template) { '--date-- --datetime--' }

        context 'and its value in the dossier are not nil' do
          before do
            dossier.champs_public
              .find { |champ| champ.type_champ == TypeDeChamp.type_champs.fetch(:date) }
              .update(value: '2017-04-15')

            dossier.champs_public
              .find { |champ| champ.type_champ == TypeDeChamp.type_champs.fetch(:datetime) }
              .update(value: '2017-09-13 09:00')
          end

          it { is_expected.to eq('15 avril 2017 13 septembre 2017 09:00') }
        end
      end
    end

    context "when using a date tag" do
      before do
        Timecop.freeze(Time.zone.local(2001, 2, 3))
        dossier.passer_en_construction!
        Timecop.freeze(Time.zone.local(2004, 5, 6))
        dossier.passer_en_instruction!(instructeur: instructeur)
        Timecop.freeze(Time.zone.local(2007, 8, 9))
        dossier.accepter!(instructeur: instructeur)
        Timecop.return
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
      before { dossier.champs_public.first.update(value: 'valeur') }

      shared_examples "treat all kinds of space as equivalent" do
        context 'and the champ has a non breaking space' do
          let(:types_de_champ_public) { [{ libelle: 'mon tag' }] }

          it { is_expected.to eq('valeur') }
        end

        context 'and the champ has an ordinary space' do
          let(:types_de_champ_public) { [{ libelle: 'mon tag' }] }

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
      let(:template) { 'text --motivation-- --date de décision--' }
      let(:state) { Dossier.states.fetch(:en_instruction) }

      subject { template_concern.send(:replace_tags, template, dossier) }

      it "does not treat motivation or date de décision as tags" do
        is_expected.to eq('text --motivation-- --date de décision--')
      end
    end

    context 'when procedure has revisions' do
      let(:types_de_champ_public) { [{ libelle: 'mon ancien libellé' }] }
      let(:draft_type_de_champ) { procedure.draft_revision.find_and_ensure_exclusive_use(procedure.draft_revision.types_de_champ.first.stable_id) }

      before do
        draft_type_de_champ.update(libelle: 'mon nouveau libellé')
        dossier.champs_public.first.update(value: 'valeur')
        procedure.update!(draft_revision: procedure.create_new_revision, published_revision: procedure.draft_revision)
      end

      context "when using the champ's original label" do
        let(:template) { '--mon ancien libellé--' }

        it "replaces the tag" do
          is_expected.to eq('valeur')
        end
      end

      context "when using the champ's revised label" do
        let(:template) { '--mon nouveau libellé--' }

        it "replaces the tag" do
          is_expected.to eq('valeur')
        end
      end
    end
  end

  describe 'tags' do
    subject { template_concern.tags }

    let(:types_de_champ_public) do
      [
        { libelle: 'public' },
        { type: :header_section, libelle: 'entête de section' },
        { type: :explication, libelle: 'explication' }
      ]
    end
    let(:types_de_champ_private) { [{ libelle: 'privé' }] }

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

    context 'when generating document for dossier having conditional' do
      include Logic
      let(:state) { Dossier.states.fetch(:en_construction) }
      let(:stable_id) { 1234 }
      let(:condition) { ds_eq(champ_value(stable_id), constant(true)) }

      let(:types_de_champ_public) do
        [
          { type: :text, libelle: 'public' },
          { type: :text, libelle: 'conditional', condition: condition }
        ]
      end

      it { is_expected.to include(include({ libelle: 'public' })) }
      it { is_expected.not_to include(include({ libelle: 'conditional' })) }
    end
  end

  describe 'used_tags_for' do
    let(:text) { 'hello world --public--, --numéro du dossier--, --yolo--' }
    subject { template_concern.used_tags_for(text) }

    let(:types_de_champ_public) do
      [
        { libelle: 'public' },
        { type: :header_section, libelle: 'entête de section' },
        { type: :explication, libelle: 'explication' }
      ]
    end

    it { is_expected.to eq(["tdc#{procedure.draft_revision.types_de_champ.first.stable_id}", 'numéro du dossier', 'yolo']) }
  end

  describe 'used_type_de_champ_tags' do
    let(:text) { 'hello world --public--, --numéro du dossier--, --yolo--' }
    subject { template_concern.used_type_de_champ_tags(text) }

    let(:types_de_champ_public) do
      [
        { libelle: 'public' },
        { type: :header_section, libelle: 'entête de section' },
        { type: :explication, libelle: 'explication' }
      ]
    end

    it { is_expected.to eq([["public", procedure.draft_revision.types_de_champ.first.stable_id], ['yolo']]) }
  end

  describe 'parser' do
    it do
      tokens = TagsSubstitutionConcern::TagsParser.parse("hello world --public--, --numéro du dossier--, un test--yolo-- encore du text\n---\n encore du text")
      expect(tokens).to eq([
        { text: "hello world " },
        { tag: "public" },
        { text: ", " },
        { tag: "numéro du dossier" },
        { text: ", un test" },
        { tag: "yolo" },
        { text: " encore du text\n" + "---\n" + " encore du text" }
      ])
    end

    it 'allow for - before tag' do
      tokens = TagsSubstitutionConcern::TagsParser.parse("hello --yolo-- --  before-- --after -- -- around -- world ---numéro-du - dossier--")
      expect(tokens).to eq([
        { text: "hello " },
        { tag: "yolo" },
        { text: " " },
        { tag: "before" },
        { text: " " },
        { tag: "after" },
        { text: " " },
        { tag: "around" },
        { text: " world -" },
        { tag: "numéro-du - dossier" }
      ])
    end

    it 'normalize white spaces' do
      tokens = TagsSubstitutionConcern::TagsParser.parse("hello --Jour(s) fixe(s)\xc2\xA0souhaité(s)\xc2\xA0:-- world".encode('utf-8'))
      expect(tokens).to eq([
        { text: "hello " },
        { tag: "Jour(s) fixe(s) souhaité(s) :" },
        { text: " world" }
      ])
    end
  end
end
