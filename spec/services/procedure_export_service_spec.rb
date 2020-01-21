require 'spec_helper'
require 'csv'

describe ProcedureExportService do
  describe 'to_data' do
    let(:procedure) { create(:procedure, :published, :for_individual, :with_all_champs) }
    subject do
      Tempfile.create do |f|
        f << ProcedureExportService.new(procedure, procedure.dossiers).to_xlsx
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
      let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :with_individual, procedure: procedure) }

      let(:nominal_headers) do
        [
          "ID",
          "Email",
          "Civilité",
          "Nom",
          "Prénom",
          "Date de naissance",
          "Archivé",
          "État du dossier",
          "Dernière mise à jour le",
          "Déposé le",
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
          "communes",
          "engagement",
          "dossier_link",
          "piece_justificative",
          "siret",
          "carte",
          "text"
        ]
      end

      it 'should have headers' do
        expect(dossiers_sheet.headers).to match(nominal_headers)
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

      context 'with a procedure routee' do
        before { procedure.groupe_instructeurs.create(label: '2') }

        let(:routee_header) { nominal_headers.insert(nominal_headers.index('textarea'), 'Groupe instructeur') }

        it { expect(dossiers_sheet.headers).to match(routee_header) }
        it { expect(dossiers_sheet.data[0][dossiers_sheet.headers.index('Groupe instructeur')]).to eq('défaut') }
      end
    end

    context 'with etablissement' do
      let(:procedure) { create(:procedure, :published, :with_all_champs) }
      let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :with_entreprise, procedure: procedure) }

      let(:dossier_etablissement) { etablissements_sheet.data[1] }
      let(:champ_etablissement) { etablissements_sheet.data[0] }

      let(:nominal_headers) do
        [
          "ID",
          "Email",
          "Entreprise raison sociale",
          "Archivé",
          "État du dossier",
          "Dernière mise à jour le",
          "Déposé le",
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
          "communes",
          "engagement",
          "dossier_link",
          "piece_justificative",
          "siret",
          "carte",
          "text"
        ]
      end

      context 'as csv' do
        subject do
          Tempfile.create do |f|
            f << ProcedureExportService.new(procedure, procedure.dossiers).to_csv
            f.rewind
            CSV.read(f.path)
          end
        end

        let(:nominal_headers) do
          [
            "ID",
            "Email",
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
            "Association date de publication",
            "Archivé",
            "État du dossier",
            "Dernière mise à jour le",
            "Déposé le",
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
            "communes",
            "engagement",
            "dossier_link",
            "piece_justificative",
            "siret",
            "carte",
            "text"
          ]
        end

        let(:dossiers_sheet_headers) { subject.first }

        it 'should have headers' do
          expect(dossiers_sheet_headers).to match(nominal_headers)
        end
      end

      it 'should have headers' do
        expect(dossiers_sheet.headers).to match(nominal_headers)

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
        expect(dossier_etablissement[1]).to eq("Dossier")
        expect(champ_etablissement[1]).to eq("siret")
      end
    end

    context 'with avis' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :with_individual, procedure: procedure) }
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
      let!(:dossiers) do
        [
          create(:dossier, :en_instruction, :with_all_champs, :with_individual, procedure: procedure),
          create(:dossier, :en_instruction, :with_all_champs, :with_individual, procedure: procedure)
        ]
      end
      let(:champ_repetition) { dossiers.first.champs.find { |champ| champ.type_champ == 'repetition' } }

      it 'should have sheets' do
        expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis', champ_repetition.libelle_for_export])
      end

      it 'should have headers' do
        expect(repetition_sheet.headers).to eq([
          "Dossier ID",
          "Ligne",
          "Nom",
          "Age"
        ])
      end

      it 'should have data' do
        expect(repetition_sheet.data.size).to eq(4)
      end

      context 'with invalid characters' do
        before do
          champ_repetition.type_de_champ.update(libelle: 'A / B \ C')
        end

        it 'should have valid sheet name' do
          expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis', "(#{champ_repetition.type_de_champ.stable_id}) A - B - C"])
        end
      end

      context 'with non unique labels' do
        let(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :with_individual, procedure: procedure) }
        let(:champ_repetition) { dossier.champs.find { |champ| champ.type_champ == 'repetition' } }
        let(:type_de_champ_repetition) { create(:type_de_champ_repetition, procedure: procedure, libelle: champ_repetition.libelle) }
        let!(:another_champ_repetition) { create(:champ_repetition, type_de_champ: type_de_champ_repetition, dossier: dossier) }

        it 'should have sheets' do
          expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis', champ_repetition.libelle_for_export, another_champ_repetition.libelle_for_export])
        end
      end
    end
  end
end
