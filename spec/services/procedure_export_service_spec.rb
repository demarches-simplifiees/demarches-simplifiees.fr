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
      tdc_first = procedure.active_revision.revision_types_de_champ.first
      tdc_last = procedure.active_revision.revision_types_de_champ.last

      tdc_first.update(position: tdc_last.position + 1)
      procedure.reload
    end

    describe 'sheets' do
      it 'should have a sheet for each record type' do
        expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis'])
      end
    end

    describe 'Dossiers sheet' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :with_individual, procedure: procedure) }

      let(:nominal_headers) do
        [
          "ID",
          "Email",
          "Civilité",
          "Nom",
          "Prénom",
          "Archivé",
          "État du dossier",
          "Dernière mise à jour le",
          "Déposé le",
          "Passé en instruction le",
          "Traité le",
          "Motivation de la décision",
          "Instructeurs",

          "auto_completion",
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
          "nationalites",
          "commune_de_polynesie",
          "code_postal_de_polynesie",
          "numero_dn",
          "regions",
          "departements",
          "communes",
          "engagement",
          "dossier_link",
          "piece_justificative",
          "siret",
          "carte",
          "te_fenua",
          "titre_identite",
          "iban",
          "annuaire_education",
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
        en_construction_at = Time.zone.at(dossiers_sheet.data[0][8] - offset.seconds)
        en_instruction_at = Time.zone.at(dossiers_sheet.data[0][9] - offset.seconds)
        expect(en_construction_at).to eq(dossier.en_construction_at.round)
        expect(en_instruction_at).to eq(dossier.en_instruction_at.round)
        expect(dossiers_sheet.data[0][dossiers_sheet.headers.index('date')]).to be_a(Date)
        expect(dossiers_sheet.data[0][dossiers_sheet.headers.index('datetime')]).to be_a(Time)
      end

      context 'with a birthdate' do
        before { procedure.update(ask_birthday: true) }

        let(:birthdate_headers) { nominal_headers.insert(nominal_headers.index('Archivé'), 'Date de naissance') }

        it { expect(dossiers_sheet.headers).to match(birthdate_headers) }
        it { expect(dossiers_sheet.data[0][dossiers_sheet.headers.index('Date de naissance')]).to be_a(Date) }
      end

      context 'with a procedure routee' do
        before { procedure.groupe_instructeurs.create(label: '2') }

        let(:routee_headers) { nominal_headers.insert(nominal_headers.index('auto_completion'), 'Groupe instructeur') }

        it { expect(dossiers_sheet.headers).to match(routee_headers) }
        it { expect(dossiers_sheet.data[0][dossiers_sheet.headers.index('Groupe instructeur')]).to eq('défaut') }
      end
    end

    describe 'Etablissement sheet' do
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
          "auto_completion",
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
          "nationalites",
          "commune_de_polynesie",
          "code_postal_de_polynesie",
          "numero_dn",
          "regions",
          "departements",
          "communes",
          "engagement",
          "dossier_link",
          "piece_justificative",
          "siret",
          "carte",
          "te_fenua",
          "titre_identite",
          "iban",
          "annuaire_education",
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
            "Établissement Numéro TAHITI",
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
            "Entreprise Numéro TAHITI siège social",
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
            "auto_completion",
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
            "nationalites",
            "commune_de_polynesie",
            "code_postal_de_polynesie",
            "numero_dn",
            "regions",
            "departements",
            "communes",
            "engagement",
            "dossier_link",
            "piece_justificative",
            "siret",
            "carte",
            "te_fenua",
            "titre_identite",
            "iban",
            "annuaire_education",
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
          "Établissement Numéro TAHITI",
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
          "Entreprise Numéro TAHITI siège social",
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

    describe 'Avis sheet' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :with_individual, procedure: procedure) }
      let!(:avis) { create(:avis, :with_answer, dossier: dossier) }

      it 'should have headers' do
        expect(avis_sheet.headers).to eq([
          "Dossier ID",
          "Question / Introduction",
          "Réponse",
          "Créé le",
          "Répondu le",
          "Instructeur",
          "Expert"
        ])
      end

      it 'should have data' do
        expect(avis_sheet.data.size).to eq(1)
      end
    end

    describe 'Repetitions sheet' do
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
          champ_repetition.type_de_champ.update(libelle: 'A / B \ C *[]?')
        end

        it 'should have valid sheet name' do
          expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis', "(#{champ_repetition.type_de_champ.stable_id}) A - B - C"])
        end
      end

      context 'with long libelle composed of utf8 characteres' do
        before do
          procedure.types_de_champ.each do |c|
            c.update!(libelle: "#{c.id} - ?/[] ééé ééé ééééééé ééééééé éééééééé. ééé éé éééééééé éé ééé. ééééé éééééééé ééé ééé.")
          end
          champ_repetition.champs.each do |c|
            c.type_de_champ.update!(libelle: "#{c.id} - Quam rem nam maiores numquam dolorem nesciunt. Cum et possimus et aut. Fugit voluptas qui qui.")
          end
        end

        it 'should have valid sheet name' do
          expect { subject }.not_to raise_error
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
