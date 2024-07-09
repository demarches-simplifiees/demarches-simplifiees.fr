require 'csv'

describe ProcedureExportService do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, types_de_champ_public:, for_individual:, ask_birthday: true) }
  let(:service) { ProcedureExportService.new(procedure, procedure.dossiers, instructeur, export_template) }
  # let(:service) { ProcedureExportService.new(procedure, procedure.dossiers, instructeur, nil) }
  let(:export_template) { create(:export_template, kind:, content:) }
  let(:for_individual) { true }
  let(:types_de_champ_public) do
    [
      { type: :text, libelle: "first champ", mandatory: true, stable_id: 1 },
      { type: :communes, libelle: "Commune", mandatory: true, stable_id: 17 },
      { type: :piece_justificative, libelle: "PJ", stable_id: 30 },
      {
        type: :repetition, mandatory: true, stable_id: 7, libelle: "Champ répétable", children:
        [
          { type: 'text', libelle: 'child first champ', stable_id: 8 },
          { type: 'text', libelle: 'child second champ', stable_id: 9 }
        ]
      }
    ]
  end

  let(:content) do
    {
      "columns" => [
        { "path" => "id", "source" => "dossier", "libelle" => "ID" },
        { "path" => "email", "source" => "dossier", "libelle" => "Email" },
        { "path" => "date_de_naissance", "source" => "dossier", "libelle" => "Date de naissance" },
        { "path" => "groupe_instructeur", "source" => "dossier", "libelle" => "Groupe instructeur" },
        { "path" => "value", "source" => "tdc", "libelle" => "first champ", "stable_id" => 1 },
        { "path" => "code", "source" => "tdc", "libelle" => "Commune (Code INSEE)", "stable_id" => 17 },
        { "path" => "value", "source" => "tdc", "libelle" => "PJ", "stable_id" => 30 },
        { "path" => "value", "source" => "repet", "libelle" => "child second champ", "stable_id" => 9, "repetition_champ_stable_id" => 7 }
      ]
    }
  end

  describe 'to_xlsx' do
    subject do
      service
        .to_xlsx
        .open { |f| SimpleXlsxReader.open(f.path) }
    end

    let(:kind) { 'xlsx' }
    let(:dossiers_sheet) { subject.sheets.first }
    let(:etablissements_sheet) { subject.sheets.second }
    let(:avis_sheet) { subject.sheets.third }
    let(:repetition_sheet) { subject.sheets.fourth }

    describe 'sheets' do
      it 'should have a sheet for each record type' do
        # expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis', '(7) Champ repetable' ])
        expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis'])
      end
    end

    describe 'Dossiers sheet' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure) }
      let(:selected_headers) { ["ID", "Email", "first champ", "Commune (Code INSEE)", "Date de naissance", "Groupe instructeur", "PJ"] }

      it 'should have only headers from export template' do
        expect(dossiers_sheet.headers).to match_array(selected_headers)
      end

      it 'should have data' do
        expect(procedure.dossiers.count).to eq 1
        expect(dossiers_sheet.data.size).to eq 1
        # expect(etablissements_sheet.data.size).to eq 1
      end

      context 'with a procedure routee' do
        let!(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure:) }
        before { create(:groupe_instructeur, label: '2', procedure:) }

        it 'find groupe instructeur data' do
          expect(dossiers_sheet.headers).to include('Groupe instructeur')
          expect(dossiers_sheet.data[0][dossiers_sheet.headers.index('Groupe instructeur')]).to eq('défaut')
        end
      end

      context 'with a dossier having multiple pjs' do
        let(:procedure) { create(:procedure, :published, :for_individual, types_de_champ_public:) }
        let!(:dossier) { create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure:) }
        let!(:dossier_2) { create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure:) }
        before do
          dossier_2.champs_public
            .find { _1.is_a? Champs::PieceJustificativeChamp }
            .piece_justificative_file
            .attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
        end
        it { expect(dossiers_sheet.data.last.last).to eq "toto.txt, toto.txt" }
      end
    end

    describe 'Etablissement sheet' do
      let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
      let(:types_de_champ_public) { [{ type: :siret, libelle: 'siret', stable_id: 40 }] }
      let!(:dossier) { create(:dossier, :en_instruction, :with_populated_champs, :with_entreprise, procedure: procedure) }

      let(:dossier_etablissement) { etablissements_sheet.data[1] }
      let(:champ_etablissement) { etablissements_sheet.data[0] }

      let(:content) do
        {
          "columns" => [
            { "path" => "id", "source" => "dossier", "libelle" => "ID" },
            { "path" => "email", "source" => "dossier", "libelle" => "Email" },
            { "path" => "siret", "source" => "tdc", "libelle" => "Siret Entreprise", "stable_id" => 40 }
          ]
        }
      end

      it 'should have siret header in dossiers sheet' do
        expect(dossiers_sheet.headers).to include('Siret Entreprise')
      end

      it 'should have headers in etablissement sheet' do
        expect(etablissements_sheet.headers).to eq([
          "Dossier ID",
          "Champ",
          "Établissement SIRET",
          "Etablissement enseigne",
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
          "Entreprise état administratif",
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
    end

    describe 'Avis sheet' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure) }
      let!(:avis) { create(:avis, :with_answer, dossier: dossier) }

      it 'should have headers and data' do
        expect(avis_sheet.headers).to eq([
          "Dossier ID",
          "Introduction",
          "Réponse",
          "Question",
          "Réponse oui/non",
          "Créé le",
          "Répondu le",
          "Instructeur",
          "Expert"
        ])
        expect(avis_sheet.data.size).to eq(1)
      end
    end

    describe 'Repetitions sheet' do
      let!(:dossiers) do
        [
          create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure),
          create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure)
        ]
      end

      describe 'sheets' do
        it 'should have a sheet for repetition' do
          expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis', '(7) Champ repetable'])
        end
      end

      it 'should have headers' do
        expect(repetition_sheet.headers).to eq([
          "Dossier ID", "Ligne", "child second champ"
        ])
      end

      it 'should have data' do
        expect(repetition_sheet.data.size).to eq 4
      end
    end
  end
end
