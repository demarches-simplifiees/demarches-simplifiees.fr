require 'spec_helper'

describe Champ do
  require 'models/champ_shared_example.rb'

  it_should_behave_like "champ_spec"

  describe '#public?' do
    let(:type_de_champ) { build(:type_de_champ) }
    let(:champ) { type_de_champ.champ.build }

    it { expect(champ.public?).to be_truthy }
    it { expect(champ.private?).to be_falsey }
  end

  describe '#public_only' do
    let(:dossier) { create(:dossier) }

    it 'partition public and private' do
      expect(dossier.champs.count).to eq(1)
      expect(dossier.champs_private.count).to eq(1)
    end
  end

  describe '#format_datetime' do
    let(:type_de_champ) { build(:type_de_champ_datetime) }
    let(:champ) { type_de_champ.champ.build(value: value) }

    before { champ.save }

    context 'when the value is sent by a modern browser' do
      let(:value) { '2017-12-31 10:23' }

      it { expect(champ.value).to eq(value) }
    end

    context 'when the value is sent by a old browser' do
      let(:value) { '31/12/2018 09:26' }

      it { expect(champ.value).to eq('2018-12-31 09:26') }
    end
  end

  describe '#multiple_select_to_string' do
    let(:type_de_champ) { build(:type_de_champ_multiple_drop_down_list) }
    let(:champ) { type_de_champ.champ.build(value: value) }

    before { champ.save }

    # when using the old form, and the ChampsService Class
    # TODO: to remove
    context 'when the value is already deserialized' do
      let(:value) { '["1", "2"]' }

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
        let(:value) { '["", "1", "2"]' }

        it { expect(champ.value).to eq('["1", "2"]') }
      end

      context 'when all choices are removed' do
        let(:value) { '[""]' }

        it { expect(champ.value).to eq(nil) }
      end
    end
  end

  describe 'for_export' do
    let(:type_de_champ) { create(:type_de_champ) }
    let(:champ) { type_de_champ.champ.build(value: value) }

    before { champ.save }

    context 'when type_de_champ is text' do
      let(:value) { '123' }

      it { expect(champ.for_export).to eq('123') }
    end

    context 'when type_de_champ is textarea' do
      let(:type_de_champ) { create(:type_de_champ_textarea) }
      let(:value) { '<b>gras<b>' }

      it { expect(champ.for_export).to eq('gras') }
    end

    context 'when type_de_champ is yes_no' do
      let(:type_de_champ) { create(:type_de_champ_yes_no) }

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

    describe '#search_terms' do
      let(:champ) { type_de_champ.champ.build(value: value) }
      subject { champ.search_terms }

      context 'for adresse champ' do
        let(:type_de_champ) { build(:type_de_champ_address) }
        let(:value) { "10 rue du Pinson qui Piaille" }

        it { is_expected.to eq([value]) }
      end

      context 'for checkbox champ' do
        let(:libelle) { 'majeur' }
        let(:type_de_champ) { build(:type_de_champ_checkbox, libelle: libelle) }

        context 'when the box is checked' do
          let(:value) { 'on' }

          it { is_expected.to eq([libelle]) }
        end

        context 'when the box is unchecked' do
          let(:value) { 'off' }

          it { is_expected.to be_nil }
        end
      end

      context 'for civilite champ' do
        let(:type_de_champ) { build(:type_de_champ_civilite) }
        let(:value) { "M." }

        it { is_expected.to eq([value]) }
      end

      context 'for date champ' do
        let(:type_de_champ) { build(:type_de_champ_date) }
        let(:value) { "2018-07-30" }

        it { is_expected.to be_nil }
      end

      context 'for date time champ' do
        let(:type_de_champ) { build(:type_de_champ_datetime) }
        let(:value) { "2018-04-29 09:00" }

        it { is_expected.to be_nil }
      end

      context 'for département champ' do
        let(:type_de_champ) { build(:type_de_champ_departements) }
        let(:value) { "69 - Rhône" }

        it { is_expected.to eq([value]) }
      end

      context 'for dossier link champ' do
        let(:type_de_champ) { build(:type_de_champ_dossier_link) }
        let(:value) { "9103132886" }

        it { is_expected.to eq([value]) }
      end

      context 'for drop down list champ' do
        let(:type_de_champ) { build(:type_de_champ_dossier_link) }
        let(:value) { "HLM" }

        it { is_expected.to eq([value]) }
      end

      context 'for email champ' do
        let(:type_de_champ) { build(:type_de_champ_email) }
        let(:value) { "machin@example.com" }

        it { is_expected.to eq([value]) }
      end

      context 'for engagement champ' do
        let(:libelle) { 'je consens' }
        let(:type_de_champ) { build(:type_de_champ_engagement, libelle: libelle) }

        context 'when the box is checked' do
          let(:value) { 'on' }

          it { is_expected.to eq([libelle]) }
        end

        context 'when the box is unchecked' do
          let(:value) { 'off' }

          it { is_expected.to be_nil }
        end
      end

      context 'for explication champ' do
        let(:type_de_champ) { build(:type_de_champ_explication) }
        let(:value) { nil }

        it { is_expected.to be_nil }
      end

      context 'for header section champ' do
        let(:type_de_champ) { build(:type_de_champ_header_section) }
        let(:value) { nil }

        it { is_expected.to be_nil }
      end

      context 'for linked drop down list champ' do
        let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list) }
        let(:champ) { type_de_champ.champ.build(primary_value: "hello", secondary_value: "world") }

        it { is_expected.to eq(["hello", "world"]) }
      end

      context 'for multiple drop down list champ' do
        let(:type_de_champ) { build(:type_de_champ_multiple_drop_down_list) }

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
        let(:type_de_champ) { build(:type_de_champ_number) }
        let(:value) { "1234" }

        it { is_expected.to eq([value]) }
      end

      context 'for pays champ' do
        let(:type_de_champ) { build(:type_de_champ_pays) }
        let(:value) { "FRANCE" }

        it { is_expected.to eq([value]) }
      end

      context 'for phone champ' do
        let(:type_de_champ) { build(:type_de_champ_phone) }
        let(:value) { "0606060606" }

        it { is_expected.to eq([value]) }
      end

      context 'for pièce justificative champ' do
        let(:type_de_champ) { build(:type_de_champ_piece_justificative) }
        let(:value) { nil }

        it { is_expected.to be_nil }
      end

      context 'for region champ' do
        let(:type_de_champ) { build(:type_de_champ_regions) }
        let(:value) { "Île-de-France" }

        it { is_expected.to eq([value]) }
      end

      context 'for siret champ' do
        let(:type_de_champ) { build(:type_de_champ_siret) }

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
          let(:champ) { type_de_champ.champ.build(value: etablissement.siret, etablissement: etablissement) }

          it { is_expected.to eq([etablissement.entreprise_siren, etablissement.entreprise_numero_tva_intracommunautaire, etablissement.entreprise_forme_juridique, etablissement.entreprise_forme_juridique_code, etablissement.entreprise_nom_commercial, etablissement.entreprise_raison_sociale, etablissement.entreprise_siret_siege_social, etablissement.entreprise_nom, etablissement.entreprise_prenom, etablissement.association_rna, etablissement.association_titre, etablissement.association_objet, etablissement.siret, etablissement.naf, etablissement.libelle_naf, etablissement.adresse, etablissement.code_postal, etablissement.localite, etablissement.code_insee_localite]) }
        end

        context 'when there is no etablissement' do
          let(:siret) { "35130347400024" }
          let(:champ) { type_de_champ.champ.build(value: siret) }

          it { is_expected.to eq([siret]) }
        end
      end

      context 'for text champ' do
        let(:type_de_champ) { build(:type_de_champ_text) }
        let(:value) { "Blah" }

        it { is_expected.to eq([value]) }
      end

      context 'for text area champ' do
        let(:type_de_champ) { build(:type_de_champ_textarea) }
        let(:value) { "Bla\nBlah de bla." }

        it { is_expected.to eq([value]) }
      end

      context 'for yes/no champ' do
        let(:type_de_champ) { build(:type_de_champ_yes_no, libelle: libelle) }
        let(:libelle) { 'avec enfant à charge' }

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

    context 'when type_de_champ is multiple_drop_down_list' do
      let(:type_de_champ) { create(:type_de_champ_multiple_drop_down_list) }
      let(:value) { '["Crétinier", "Mousserie"]' }

      it { expect(champ.for_export).to eq('Crétinier, Mousserie') }
    end
  end

  describe '#enqueue_virus_check' do
    let(:champ) { type_de_champ.champ.build(value: nil) }

    context 'when type_champ is type_de_champ_piece_justificative' do
      let(:type_de_champ) { create(:type_de_champ_piece_justificative) }

      context 'and there is a blob' do
        before do
          champ.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
          champ.save
        end

        it { expect(champ.piece_justificative_file.virus_scanner.started?).to be_truthy }
      end
    end
  end

  describe "repetition" do
    let(:dossier) { create(:dossier) }
    let(:champ) { Champs::RepetitionChamp.create(dossier: dossier) }
    let(:champ_text) { create(:champ_text, row: 0) }
    let(:champ_integer_number) { create(:champ_integer_number, row: 0) }
    let(:champ_text_attrs) { attributes_for(:champ_text, row: 1) }
    let(:champ_text_row_1) { create(:champ_text, row: 1, parent: champ) }

    it "associates nested champs to the parent dossier" do
      expect(champ.rows.size).to eq(0)
      dossier.reload
      expect(dossier.champs.size).to eq(2)

      dossier.update(champs_attributes: [
        {
          id: champ.id,
          champs_attributes: [champ_text_attrs]
        }
      ])

      champ.reload
      dossier.reload
      expect(dossier.champs.size).to eq(2)
      expect(champ.rows.size).to eq(1)

      expect(champ.champs.first.dossier).to eq(dossier)

      # Make champs ordered
      champ_integer_number.type_de_champ.update(order_place: 0)
      champ_text.type_de_champ.update(order_place: 1)

      champ.champs << champ_integer_number
      row = champ.reload.rows.first
      expect(row.size).to eq(1)
      expect(row.first).to eq(champ_integer_number)

      champ.champs << champ_text
      row = champ.reload.rows.first
      expect(row.size).to eq(2)
      expect(row.second).to eq(champ_text)

      expect(champ.rows.size).to eq(2)

      expect(champ_text_row_1.dossier_id).to eq(champ.dossier_id)
    end
  end
end
