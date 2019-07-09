require 'spec_helper'

describe ProcedureExportV2Service do
  describe 'to_data' do
    let(:procedure) { create(:procedure, :published, :with_all_champs) }
    subject do
      Tempfile.create do |f|
        f << ProcedureExportV2Service.new(procedure).to_xlsx
        f.rewind
        SimpleXlsxReader.open(f.path)
      end
    end

    let(:dossiers_sheet) { subject.sheets.first }
    let(:etablissements_sheet) { subject.sheets.second }
    let(:avis_sheet) { subject.sheets.third }
    let(:repetition_sheet) { subject.sheets.fourth }

    before do
      # change one tdc place to check if the header is ordered
      tdc_first = procedure.types_de_champ.first
      tdc_last = procedure.types_de_champ.last

      tdc_first.update(order_place: tdc_last.order_place + 1)
      procedure.reload
    end

    context 'dossiers' do
      it 'should have sheets' do
        expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis'])
      end
    end

    context 'with dossier' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :for_individual, procedure: procedure) }

      it 'should have headers' do
        expect(dossiers_sheet.headers).to eq([
          "ID",
          "Email",
          "Civilité",
          "Nom",
          "Prénom",
          "Date de naissance",
          "Archivé",
          "État du dossier",
          "Dernière mise à jour le",
          "Passé en construction le",
          "Passé en instruction le",
          "Traité le",
          "Motivation de la décision",
          "Instructeurs",
          "textarea",
          "date",
          "datetime",
          "number",
          "decimal_number",
          "integer_number",
          "checkbox",
          "civilite",
          "email",
          "phone",
          "address",
          "yes_no",
          "simple_drop_down_list",
          "multiple_drop_down_list",
          "linked_drop_down_list",
          "pays",
          "regions",
          "departements",
          "engagement",
          "dossier_link",
          "piece_justificative",
          "siret",
          "carte",
          "text"
        ])
      end

      it 'should have data' do
        expect(dossiers_sheet.data.size).to eq(1)
        expect(etablissements_sheet.data.size).to eq(1)

        # SimpleXlsxReader is transforming datetimes in utc... It is only used in test so we just hack around.
        offset = dossier.en_construction_at.utc_offset
        en_construction_at = Time.zone.at(dossiers_sheet.data[0][9] - offset.seconds)
        en_instruction_at = Time.zone.at(dossiers_sheet.data[0][10] - offset.seconds)
        expect(en_construction_at).to eq(dossier.en_construction_at.round)
        expect(en_instruction_at).to eq(dossier.en_instruction_at.round)
      end
    end

    context 'with etablissement' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :with_entreprise, procedure: procedure) }

      it 'should have headers' do
        expect(etablissements_sheet.headers).to eq([
          "Dossier ID",
          "Champ",
          "Établissement SIRET",
          "Établissement siège social",
          "Établissement NAF",
          "Établissement libellé NAF",
          "Établissement Adresse",
          "Établissement numero voie",
          "Établissement type voie",
          "Établissement nom voie",
          "Établissement complément adresse",
          "Établissement code postal",
          "Établissement localité",
          "Établissement code INSEE localité",
          "Entreprise SIREN",
          "Entreprise capital social",
          "Entreprise numero TVA intracommunautaire",
          "Entreprise forme juridique",
          "Entreprise forme juridique code",
          "Entreprise nom commercial",
          "Entreprise raison sociale",
          "Entreprise SIRET siège social",
          "Entreprise code effectif entreprise",
          "Entreprise date de création",
          "Entreprise nom",
          "Entreprise prénom",
          "Association RNA",
          "Association titre",
          "Association objet",
          "Association date de création",
          "Association date de déclaration",
          "Association date de publication"
        ])
      end

      it 'should have data' do
        expect(etablissements_sheet.data.size).to eq(2)
      end
    end

    context 'with avis' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :for_individual, procedure: procedure) }
      let!(:avis) { create(:avis, :with_answer, dossier: dossier) }

      it 'should have headers' do
        expect(avis_sheet.headers).to eq([
          "Dossier ID",
          "Question / Introduction",
          "Réponse",
          "Créé le",
          "Répondu le"
        ])
      end

      it 'should have data' do
        expect(avis_sheet.data.size).to eq(1)
      end
    end

    context 'with repetitions' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :for_individual, procedure: procedure) }
      let(:champ_repetition) { dossier.champs.find { |champ| champ.type_champ == 'repetition' } }
      let(:type_de_champ_text) { create(:type_de_champ_text, order_place: 0, parent: champ_repetition.type_de_champ) }
      let(:type_de_champ_number) { create(:type_de_champ_number, order_place: 1, parent: champ_repetition.type_de_champ) }

      before do
        create(:champ_text, row: 0, type_de_champ: type_de_champ_text, parent: champ_repetition)
        create(:champ_number, row: 0, type_de_champ: type_de_champ_number, parent: champ_repetition)
        create(:champ_text, row: 1, type_de_champ: type_de_champ_text, parent: champ_repetition)
        create(:champ_number, row: 1, type_de_champ: type_de_champ_number, parent: champ_repetition)
      end

      it 'should have sheets' do
        expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis', champ_repetition.libelle])
      end

      it 'should have headers' do
        expect(repetition_sheet.headers).to eq([
          "Dossier ID",
          "Ligne",
          type_de_champ_text.libelle,
          type_de_champ_number.libelle
        ])
      end

      it 'should have data' do
        expect(repetition_sheet.data.size).to eq(2)
      end
    end
  end
end
