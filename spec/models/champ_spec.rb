describe Champ do
  include ActiveJob::TestHelper

  require 'models/champ_shared_example.rb'

  it_should_behave_like "champ_spec"

  describe "associations" do
    it { is_expected.to belong_to(:dossier) }

    context 'when the parent dossier is discarded' do
      let(:discarded_dossier) { create(:dossier, :discarded) }
      subject(:champ) { discarded_dossier.champs_public.first }

      it { expect(champ.reload.dossier).to eq discarded_dossier }
    end
  end

  describe "normalization" do
    it "should remove null bytes before save" do
      champ = create(:champ, value: "foo\u0000bar")
      expect(champ.value).to eq "foobar"
    end
  end

  describe '#public?' do
    let(:type_de_champ) { build(:type_de_champ) }
    let(:champ) { type_de_champ.champ.build }

    it { expect(champ.public?).to be_truthy }
    it { expect(champ.private?).to be_falsey }
  end

  describe '#public_only' do
    let(:dossier) { create(:dossier) }

    it 'partition public and private' do
      expect(dossier.champs_public.count).to eq(1)
      expect(dossier.champs_private.count).to eq(1)
    end
  end

  describe '#public_ordered' do
    let(:procedure) { create(:simple_procedure) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    context 'when a procedure has 2 revisions' do
      it 'does not duplicate the champs' do
        expect(dossier.champs_public.count).to eq(1)
        expect(procedure.revisions.count).to eq(2)
      end
    end
  end

  describe '#private_ordered' do
    let(:procedure) { create(:procedure, :with_type_de_champ_private) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    context 'when a procedure has 2 revisions' do
      before { procedure.publish }

      it 'does not duplicate the champs private' do
        expect(dossier.champs_private.count).to eq(1)
        expect(procedure.revisions.count).to eq(2)
      end
    end
  end

  describe '#sections' do
    let(:procedure) do
      create(:procedure, types_de_champ_public: [{}, { type: :header_section }, { type: :repetition, mandatory: true, children: [{ type: :header_section }] }], types_de_champ_private: [{}, { type: :header_section }])
    end
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:public_champ) { dossier.champs_public.first }
    let(:private_champ) { dossier.champs_private.first }
    let(:champ_in_repetition) { dossier.champs_public.find(&:repetition?).champs.first }
    let(:standalone_champ) { build(:champ, type_de_champ: build(:type_de_champ), dossier: build(:dossier)) }
    let(:public_sections) { dossier.champs_public.filter(&:header_section?) }
    let(:private_sections) { dossier.champs_private.filter(&:header_section?) }
    let(:sections_in_repetition) { champ_in_repetition.parent.champs.filter(&:header_section?) }

    it 'returns the sibling sections of a champ' do
      expect(public_sections).not_to be_empty
      expect(private_sections).not_to be_empty
      expect(sections_in_repetition).not_to be_empty
    end
  end

  describe '#format_datetime' do
    let(:champ) { build(:champ_datetime, value: value) }

    before { champ.save! }

    context 'when the value is sent by a modern browser' do
      let(:value) { '2017-12-31 10:23' }

      it { expect(champ.value).to eq(Time.zone.parse("2017-12-31T10:23:00").iso8601) }
    end

    context 'when the value is sent by a old browser' do
      let(:value) { '31/12/2018 09:26' }

      it { expect(champ.value).to eq(Time.zone.parse("2018-12-31T09:26:00").iso8601) }
    end
  end

  describe '#multiple_select_to_string' do
    let(:champ) { build(:champ_multiple_drop_down_list, value: value) }

    before { champ.save! }

    # when using the old form, and the ChampsService Class
    # TODO: to remove
    context 'when the value is already deserialized' do
      let(:value) { '["val1","val2"]' }

      it { expect(champ.value).to eq(value) }

      context 'when the value is nil' do
        let(:value) { nil }

        it { expect(champ.value).to eq(value) }
      end
    end

    # for explanation for the "" entry, see
    # https://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/select
    # GOTCHA
    context 'when the value is not already deserialized' do
      context 'when a choice is selected' do
        let(:value) { '["", "val1", "val2"]' }

        it { expect(champ.value).to eq('["val1","val2"]') }
      end

      context 'when all choices are removed' do
        let(:value) { '[""]' }

        it { expect(champ.value).to eq(nil) }
      end
    end
  end

  describe 'for_export' do
    let(:champ) { create(:champ_text, value: value) }

    context 'when type_de_champ is text' do
      let(:value) { '123' }

      it { expect(champ.for_export).to eq('123') }
    end

    context 'when type_de_champ is textarea' do
      let(:champ) { create(:champ_textarea, value: value) }
      let(:value) { '<b>gras<b>' }

      it { expect(champ.for_export).to eq('gras') }
    end

    context 'when type_de_champ is yes_no' do
      let(:champ) { create(:champ_yes_no, value: value) }

      context 'if yes' do
        let(:value) { 'true' }

        it { expect(champ.for_export).to eq('Oui') }
      end

      context 'if no' do
        let(:value) { 'false' }

        it { expect(champ.for_export).to eq('Non') }
      end

      context 'if nil' do
        let(:value) { nil }

        it { expect(champ.for_export).to eq('Non') }
      end
    end

    context 'when type_de_champ is multiple_drop_down_list' do
      let(:champ) { create(:champ_multiple_drop_down_list, value:) }
      let(:value) { '["Crétinier", "Mousserie"]' }

      it { expect(champ.for_export).to eq('Crétinier, Mousserie') }
    end

    # pf displays links for PJs
    context 'when type_de_champ is piece_justificative' do
      let(:champ) { create(:champ_piece_justificative) }

      it { expect(champ.for_export).to eq('toto.txt') }
    end
  end

  describe '#for_tag' do
    # pf displays links for PJs
    context 'when type_de_champ is piece_justificative' do
      let(:champ) { create(:champ_piece_justificative) }

      it { expect(champ.for_tag).to include('<a href="http://') }
    end

    context 'when type_de_champ is numero_dn' do
      let(:champ) { create(:champ_numero_dn) }

      it do
        expect(champ.for_tag).to eq("1234567")
        expect(champ.for_tag(:date_de_naissance)).to eq('01 janvier 2000')
      end
    end

    context 'when type_de_champ is commune de polynesie' do
      let(:champ) { create(:champ_commune_de_polynesie) }

      it do
        expect(champ.for_tag).to eq("Arue")
        expect(champ.for_tag(:ile)).to eq('Tahiti')
        expect(champ.for_tag(:archipel)).to eq('Iles Du Vent')
        expect(champ.for_tag(:code_postal)).to eq(98701)
      end
    end

    context 'when type_de_champ is code postal de polynesie' do
      let(:champ) { create(:champ_code_postal_de_polynesie) }

      it do
        expect(champ.for_tag).to eq(98701)
        expect(champ.for_tag(:ile)).to eq('Tahiti')
        expect(champ.for_tag(:archipel)).to eq('Iles Du Vent')
        expect(champ.for_tag(:commune)).to eq('Arue')
      end
    end

    context 'when type_de_champ and champ.type mismatch' do
      let(:champ_yes_no) { create(:champ_yes_no, value: 'true') }
      let(:champ_text) { create(:champ_text, value: 'Hello') }

      it { expect(TypeDeChamp.champ_value_for_export(champ_text.type_champ, champ_yes_no)).to eq(nil) }
      it { expect(TypeDeChamp.champ_value_for_export(champ_yes_no.type_champ, champ_text)).to eq('Non') }
    end
  end

  describe '#search_terms' do
    subject { champ.search_terms }

    context 'for adresse champ' do
      let(:champ) { create(:champ_address, value:) }
      let(:value) { "10 rue du Pinson qui Piaille" }

      it { is_expected.to eq([value]) }
    end

    context 'for checkbox champ' do
      let(:libelle) { champ.libelle }
      let(:champ) { create(:champ_checkbox, value:) }

      context 'when the box is checked' do
        let(:value) { 'true' }

        it { is_expected.to eq([libelle]) }
      end

      context 'when the box is unchecked' do
        let(:value) { 'false' }

        it { is_expected.to be_nil }
      end
    end

    context 'for civilite champ' do
      let(:champ) { create(:champ_civilite, value:) }
      let(:value) { "M." }

      it { is_expected.to eq([value]) }
    end

    context 'for date champ' do
      let(:champ) { create(:champ_date, value:) }
      let(:value) { "2018-07-30" }

      it { is_expected.to be_nil }
    end

    context 'for date time champ' do
      let(:champ) { create(:champ_datetime, value:) }
      let(:value) { "2018-04-29 09:00" }

      it { is_expected.to be_nil }
    end

    context 'for département champ' do
      let(:champ) { create(:champ_departements, value:) }
      let(:value) { "69" }

      it { is_expected.to eq(['69 – Rhône']) }
    end

    context 'for nationalités champ' do
      let(:champ) { create(:champ_nationalites, value:) }
      let(:value) { "Française" }

      it { is_expected.to eq([value]) }
    end

    context 'for commune de polynésie champ' do
      let(:champ) { create(:champ_commune_de_polynesie, value:) }
      let(:value) { "Arue - Tahiti - 98701" }

      it { is_expected.to eq(["Arue"]) }
    end

    context 'for code postal de polynésie champ' do
      let(:champ) { create(:champ_code_postal_de_polynesie, value:) }
      let(:value) { "98701 - Arue - Tahiti" }

      it { is_expected.to eq(["98701"]) }
    end

    context 'for dossier link champ' do
      let(:champ) { create(:champ_dossier_link, value:) }
      let(:value) { "9103132886" }

      it { is_expected.to eq([value]) }
    end

    context 'for drop down list champ' do
      let(:champ) { create(:champ_dossier_link, value:) }
      let(:value) { "HLM" }

      it { is_expected.to eq([value]) }
    end

    context 'for email champ' do
      let(:champ) { build(:champ_email, value:) }
      let(:value) { "machin@example.com" }

      it { is_expected.to eq([value]) }
    end

    context 'for explication champ' do
      let(:champ) { build(:champ_explication) }

      it { is_expected.to be_nil }
    end

    context 'for header section champ' do
      let(:champ) { build(:champ_header_section) }

      it { is_expected.to be_nil }
    end

    context 'for linked drop down list champ' do
      let(:champ) { create(:champ_linked_drop_down_list, primary_value: "hello", secondary_value: "world") }

      it { is_expected.to eq(["hello", "world"]) }
    end

    context 'for numero dn champ' do
      let(:champ) { create(:champ_numero_dn, numero_dn: "1234567", date_de_naissance: "2000-01-01") }

      it { is_expected.to eq(["1234567", "01/01/2000"]) }
    end

    context 'for multiple drop down list champ' do
      let(:champ) { build(:champ_multiple_drop_down_list, value:) }

      context 'when there are multiple values selected' do
        let(:value) { JSON.generate(['goodbye', 'cruel', 'world']) }

        it { is_expected.to eq(["goodbye", "cruel", "world"]) }
      end

      context 'when there is no value selected' do
        let(:value) { nil }

        it { is_expected.to eq([]) }
      end
    end

    context 'for number champ' do
      let(:champ) { build(:champ_number, value:) }
      let(:value) { "1234" }

      it { is_expected.to eq([value]) }
    end

    context 'for pays champ' do
      let(:champ) { build(:champ_pays, value:) }
      let(:value) { "FR" }

      it { is_expected.to eq(['France']) }
    end

    context 'for nationalites champ' do
      let(:champ) { build(:champ_nationalites) }
      let(:value) { "Française" }

      it { is_expected.to eq([value]) }
    end

    context 'for phone champ' do
      let(:champ) { build(:champ_phone, value:) }
      let(:value) { "06 06 06 06 06" }

      it { is_expected.to eq([value]) }
    end

    context 'for pièce justificative champ' do
      let(:champ) { build(:champ_piece_justificative, value:) }
      let(:value) { nil }

      it { is_expected.to be_nil }
    end

    context 'for region champ' do
      let(:champ) { build(:champ_regions, value:) }
      let(:value) { "11" }

      it { is_expected.to eq(['Île-de-France']) }
    end

    context 'for siret champ' do
      context 'when there is an etablissement' do
        let(:etablissement) do
          build(
            :etablissement,
            siret: "35130347400024",
            siege_social: true,
            naf: "9004Z",
            libelle_naf: "Gestion de salles de spectacles",
            adresse: "MAISON JEUNES CULTURE FABRIQUE\r\n98 RUE DE PARIS\r\n59200 TOURCOING\r\nFRANCE\r\n",
            numero_voie: "98",
            type_voie: "RUE",
            nom_voie: "DE PARIS",
            code_postal: "59200",
            localite: "TOURCOING",
            code_insee_localite: "59599",
            entreprise_siren: "351303474",
            entreprise_numero_tva_intracommunautaire: "FR02351303474",
            entreprise_forme_juridique: "Association déclarée ",
            entreprise_forme_juridique_code: "9220",
            entreprise_nom_commercial: "",
            entreprise_raison_sociale: "MAISON DES JEUNES ET DE LA CULTURE DE LA FABRIQUE",
            entreprise_siret_siege_social: "35130347400024",
            entreprise_nom: 'Martin',
            entreprise_prenom: 'Guillaume',
            entreprise_code_effectif_entreprise: "12",
            entreprise_date_creation: "1989-07-09",
            association_rna: "W595004053",
            association_titre: "MAISON DES JEUNES ET DE LA CULTURE DE LA FABRIQUE",
            association_objet: "Création, gestion et animation de la Maison des Jeunes et de la Culture de la Fabrique, qui constitue un élément essentiel de la vie sociale et culturelle d'un territoire de vie : pays, agglomération, ville, communauté de communes, village, quartier ...",
            association_date_creation: "1962-05-23",
            association_date_declaration: "2016-12-02",
            association_date_publication: "1962-05-31"
          )
        end
        let(:champ) { create(:champ_siret, value: etablissement.siret, etablissement:) }

        it { is_expected.to eq([etablissement.entreprise_siren, etablissement.entreprise_numero_tva_intracommunautaire, etablissement.entreprise_forme_juridique, etablissement.entreprise_forme_juridique_code, etablissement.entreprise_nom_commercial, etablissement.entreprise_raison_sociale, etablissement.entreprise_siret_siege_social, etablissement.entreprise_nom, etablissement.entreprise_prenom, etablissement.association_rna, etablissement.association_titre, etablissement.association_objet, etablissement.siret, etablissement.enseigne, etablissement.naf, etablissement.libelle_naf, etablissement.adresse, etablissement.code_postal, etablissement.localite, etablissement.code_insee_localite]) }
      end

      context 'when there is no etablissement' do
        let(:champ) { create(:champ_siret, value:, etablissement: nil) }
        let(:value) { "35130347400024" }

        it { is_expected.to eq([value]) }
      end
    end

    context 'for text champ' do
      let(:champ) { build(:champ_text, value:) }
      let(:value) { "Blah" }

      it { is_expected.to eq([value]) }
    end

    context 'for text area champ' do
      let(:champ) { build(:champ_textarea, value:) }
      let(:value) { "Bla\nBlah de bla." }

      it { is_expected.to eq([value]) }
    end

    context 'for yes/no champ' do
      let(:champ) { build(:champ_yes_no, value:) }
      let(:libelle) { champ.libelle }

      context 'when the box is checked' do
        let(:value) { "true" }

        it { is_expected.to eq([libelle]) }
      end

      context 'when the box is unchecked' do
        let(:value) { "false" }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#enqueue_virus_scan' do
    context 'when type_champ is type_de_champ_piece_justificative' do
      let(:champ) { build(:champ_piece_justificative) }

      context 'and there is a blob' do
        before do
          allow(ClamavService).to receive(:safe_file?).and_return(true)
        end

        subject do
          champ.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
          champ.save!
          champ
        end

        it 'marks the file as pending virus scan' do
          expect(subject.piece_justificative_file.first.virus_scanner.started?).to be_truthy
        end

        it 'marks the file as safe once the scan completes' do
          subject
          perform_enqueued_jobs
          expect(champ.reload.piece_justificative_file.first.virus_scanner.safe?).to be_truthy
        end
      end
    end
  end

  describe '#enqueue_watermark_job' do
    context 'when type_champ is type_de_champ_titre_identite' do
      let(:type_de_champ) { create(:type_de_champ_titre_identite) }
      let(:champ) { build(:champ_titre_identite, type_de_champ: type_de_champ, skip_default_attachment: true) }

      before do
        allow(ClamavService).to receive(:safe_file?).and_return(true)
      end

      subject do
        champ.piece_justificative_file.attach(fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png'))
        champ.save!
        champ
      end

      it 'marks the file as needing watermarking' do
        expect(subject.piece_justificative_file.first.watermark_pending?).to be_truthy
      end

      it 'watermarks the file' do
        subject
        perform_enqueued_jobs
        expect(champ.reload.piece_justificative_file.first.watermark_pending?).to be_falsy
        expect(champ.reload.piece_justificative_file.first.blob.watermark_done?).to be_truthy
      end
    end
  end

  describe 'repetition' do
    let(:procedure) { create(:procedure, :published, types_de_champ_private: [{}], types_de_champ_public: [{}, { type: :repetition, mandatory: true, children: [{}, { type: :integer_number }] }]) }
    let(:tdc_repetition) { procedure.active_revision.types_de_champ_public.find(&:repetition?) }
    let(:tdc_text) { procedure.active_revision.children_of(tdc_repetition).first }

    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:champ) { dossier.champs_public.find(&:repetition?) }
    let(:champ_text) { champ.champs.find { |c| c.type_champ == 'text' } }
    let(:champ_integer) { champ.champs.find { |c| c.type_champ == 'integer_number' } }
    let(:champ_text_attrs) { attributes_for(:champ_text, type_de_champ: tdc_text, row_id: ULID.generate) }

    context 'when creating the model directly' do
      let(:champ_text_row_1) { create(:champ_text, type_de_champ: tdc_text, row_id: ULID.generate, parent: champ, dossier: nil) }

      it 'associates nested champs to the parent dossier' do
        expect(champ_text_row_1.dossier_id).to eq(champ.dossier_id)
      end
    end
  end

  describe '#log_fetch_external_data_exception' do
    let(:champ) { create(:champ_siret) }

    context "add execption to the log" do
      before do
        champ.log_fetch_external_data_exception(StandardError.new('My special exception!'))
      end

      it { expect(champ.fetch_external_data_exceptions).to eq(['#<StandardError: My special exception!>']) }
    end
  end

  describe "fetch_external_data" do
    let(:champ) { create(:champ_rnf, data: 'some data') }

    context "cleanup_if_empty" do
      it "remove data if external_id changes" do
        expect(champ.data).to_not be_nil
        champ.update(external_id: 'external_id')
        expect(champ.data).to be_nil
      end
    end

    context "fetch_external_data_later" do
      let(:data) { 'some other data' }

      it "fill data from external source" do
        expect_any_instance_of(Champs::RNFChamp).to receive(:fetch_external_data) { data }

        perform_enqueued_jobs do
          champ.update(external_id: 'external_id')
        end
        expect(champ.reload.data).to eq data
      end
    end
  end

  describe "#input_name" do
    let(:champ) { create(:champ_text) }
    it { expect(champ.input_name).to eq "dossier[champs_public_attributes][#{champ.public_id}]" }

    context "when private" do
      let(:champ) { create(:champ_text, private: true) }
      it { expect(champ.input_name).to eq "dossier[champs_private_attributes][#{champ.public_id}]" }
    end

    context "when has parent" do
      let(:champ) { create(:champ_text, parent: create(:champ_text)) }
      it { expect(champ.input_name).to eq "dossier[champs_public_attributes][#{champ.public_id}]" }
    end

    context "when has private parent" do
      let(:champ) { create(:champ_text, private: true, parent: create(:champ_text, private: true)) }
      it { expect(champ.input_name).to eq "dossier[champs_private_attributes][#{champ.public_id}]" }
    end
  end

  describe '#update_with_external_data!' do
    let(:champ) { create(:champ_siret) }
    let(:data) { "data" }
    subject { champ.update_with_external_data!(data: data) }

    it { expect { subject }.to change { champ.reload.data }.to(data) }
  end

  describe 'dom_id' do
    let(:champ) { build(:champ_text, row_id: '1234') }

    it { expect(champ.public_id).to eq("#{champ.stable_id}-#{champ.row_id}") }
    it { expect(ActionView::RecordIdentifier.dom_id(champ)).to eq("champ_#{champ.public_id}") }
    it { expect(ActionView::RecordIdentifier.dom_id(champ.type_de_champ)).to eq("type_de_champ_#{champ.type_de_champ.id}") }
    it { expect(ActionView::RecordIdentifier.dom_class(champ)).to eq("champ") }
  end

  describe 'clone' do
    subject { champ.clone(fork) }

    context 'when champ public' do
      let(:champ) { create(:champ_piece_justificative, private: false) }

      context 'when fork' do
        let(:fork) { true }
        it do
          expect(subject.piece_justificative_file).to be_attached
        end
      end

      context 'when not fork' do
        let(:fork) { false }
        it do
          expect(subject.piece_justificative_file).to be_attached
        end
      end
    end

    context 'champ private' do
      let(:champ) { create(:champ_piece_justificative, private: true) }

      context 'when fork' do
        let(:fork) { true }
        it do
          expect(subject.piece_justificative_file).to be_attached
        end
      end

      context 'when not fork' do
        let(:fork) { false }
        it do
          expect(subject.piece_justificative_file).not_to be_attached
        end
      end
    end
  end
end
