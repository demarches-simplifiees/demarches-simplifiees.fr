require 'csv'

describe ProcedureExportService do
  let(:procedure) { create(:procedure, :published, :for_individual, :with_all_champs) }
  let(:service) { ProcedureExportService.new(procedure, procedure.dossiers) }

  let(:tdc_to_ignore) { Set['repetition', 'header_section', 'explication'] }
  let(:champ_headers) do
    TypeDeChamp.type_champs.keys.reject { |tdc| tdc_to_ignore.include?(tdc) }.flat_map do |tdc|
      case tdc
      when 'drop_down_list'
        'simple_drop_down_list'
      when 'communes'
        ['communes', "communes (Code insee)", "communes (Département)"]
      when 'commune_de_polynesie'
        ["commune_de_polynesie", "commune_de_polynesie (Archipel)", "commune_de_polynesie (Code postal)", "commune_de_polynesie (Ile)"]
      when 'code_postal_de_polynesie'
        ["code_postal_de_polynesie", "code_postal_de_polynesie (Archipel)", "code_postal_de_polynesie (Commune)", "code_postal_de_polynesie (Ile)"]
      when 'departements', 'regions', 'pays'
        [tdc, "#{tdc} (Code)"]
      when 'epci'
        [tdc, "#{tdc} (Code)", "#{tdc} (Département)"]
      else
        tdc
      end
    end
  end

  describe 'to_xlsx' do
    subject do
      service
        .to_xlsx
        .open { |f| SimpleXlsxReader.open(f.path) }
    end

    let(:dossiers_sheet) { subject.sheets.first }
    let(:etablissements_sheet) { subject.sheets.second }
    let(:avis_sheet) { subject.sheets.third }
    let(:repetition_sheet) { subject.sheets.fourth }

    before do
      # change one tdc place to check if the header is ordered
      tdc_first = procedure.active_revision.revision_types_de_champ_public.first
      tdc_last = procedure.active_revision.revision_types_de_champ_public.last

      tdc_first.update(position: tdc_last.position + 1)
      procedure.reload
    end

    describe 'sheets' do
      it 'should have a sheet for each record type' do
        expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis'])
      end
    end

    describe 'Dossiers sheet' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure) }

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
          *champ_headers[1..-1],
          champ_headers[0]
        ]
      end

      it 'should have headers' do
        expect(dossiers_sheet.headers).to match_array(nominal_headers)
      end

      it 'should have data' do
        expect(dossiers_sheet.data.size).to eq(1)
        expect(etablissements_sheet.data.size).to eq(1)

        # SimpleXlsxReader is transforming datetimes in utc... It is only used in test so we just hack around.
        offset = dossier.depose_at.utc_offset
        depose_at = Time.zone.at(dossiers_sheet.data[0][8] - offset.seconds)
        en_instruction_at = Time.zone.at(dossiers_sheet.data[0][9] - offset.seconds)
        expect(dossiers_sheet.data.first.size).to eq(nominal_headers.size)
        expect(depose_at).to eq(dossier.depose_at.round)
        expect(en_instruction_at).to eq(dossier.en_instruction_at.round)
        expect(dossiers_sheet.data[0][dossiers_sheet.headers.index('date')]).to be_a(Date)
        expect(dossiers_sheet.data[0][dossiers_sheet.headers.index('datetime')]).to be_a(Time)
      end

      context 'with a birthdate' do
        before { procedure.update(ask_birthday: true) }

        let(:birthdate_headers) { nominal_headers.insert(nominal_headers.index('Archivé'), 'Date de naissance') }

        it { expect(dossiers_sheet.headers).to match_array(birthdate_headers) }
        it { expect(dossiers_sheet.data[0][dossiers_sheet.headers.index('Date de naissance')]).to be_a(Date) }
      end

      context 'with a procedure routee' do
        before { create(:groupe_instructeur, label: '2', procedure: procedure) }

        let(:routee_headers) { nominal_headers.insert(nominal_headers.index('textarea'), 'Groupe instructeur') }

        it { expect(dossiers_sheet.headers).to match_array(routee_headers) }
        it { expect(dossiers_sheet.data[0][dossiers_sheet.headers.index('Groupe instructeur')]).to eq('défaut') }
      end

      context 'with a dossier having multiple pjs' do
        let!(:dossier_2) { create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure) }
        before do
          dossier_2.champs_public
            .find { _1.is_a? Champs::PieceJustificativeChamp }
            .piece_justificative_file
            .attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
        end
        it { expect(dossiers_sheet.data.first.size).to eq(nominal_headers.size) }
      end
    end

    describe 'Etablissement sheet' do
      let(:procedure) { create(:procedure, :published, :with_all_champs) }
      let!(:dossier) { create(:dossier, :en_instruction, :with_populated_champs, :with_entreprise, procedure: procedure) }

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
          *champ_headers[1..-1],
          champ_headers[0]
        ]
      end

      context 'as csv' do
        subject do
          ProcedureExportService.new(procedure, procedure.dossiers)
            .to_csv
            .open { |f| CSV.read(f.path) }
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
            "Entreprise état administratif",
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
            *champ_headers[1..-1],
            champ_headers[0]
          ]
        end

        let(:dossiers_sheet_headers) { subject.first }

        it 'should have headers' do
          expect(dossiers_sheet_headers).to match_array(nominal_headers)
        end
      end

      it 'should have headers' do
        expect(dossiers_sheet.headers).to match_array(nominal_headers)

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

      it 'should have data' do
        expect(etablissements_sheet.data.size).to eq(2)
        expect(dossier_etablissement[1]).to eq("Dossier")
        expect(champ_etablissement[1]).to eq("siret")
      end
    end

    describe 'Avis sheet' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure) }
      let!(:avis) { create(:avis, :with_answer, dossier: dossier) }

      it 'should have headers' do
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
      end

      it 'should have data' do
        expect(avis_sheet.data.size).to eq(1)
      end
    end

    describe 'Repetitions sheet' do
      let(:procedure) { create(:procedure, :published, :for_individual, types_de_champ_public: [{ type: :repetition, children: [{ libelle: 'Nom' }, { libelle: 'Age' }] }]) }
      let!(:dossiers) do
        [
          create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure),
          create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure)
        ]
      end
      let(:champ_repetition) { dossiers.first.champs_public.find { |champ| champ.type_champ == 'repetition' } }

      it 'should have sheets' do
        expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis', champ_repetition.libelle_for_export])
      end

      context 'with cloned procedure' do
        let(:other_parent) { create(:type_de_champ_repetition, stable_id: champ_repetition.stable_id) }

        before do
          create(:type_de_champ, parent: create(:procedure_revision_type_de_champ, type_de_champ: other_parent, revision: create(:procedure).active_revision, position: 0))
        end

        it 'should have headers' do
          expect(repetition_sheet.headers).to eq([
            "Dossier ID",
            "Ligne",
            "Nom",
            "Age"
          ])
        end
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
          procedure.active_revision.types_de_champ_public.each do |c|
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
        let(:dossier) { create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure) }
        let(:champ_repetition) { dossier.champs_public.find { |champ| champ.type_champ == 'repetition' } }
        let(:type_de_champ_repetition) { create(:type_de_champ_repetition, :with_types_de_champ, procedure: procedure, libelle: champ_repetition.libelle) }
        let!(:another_champ_repetition) { create(:champ_repetition, type_de_champ: type_de_champ_repetition, dossier: dossier) }

        it 'should have sheets' do
          expect(subject.sheets.map(&:name)).to eq(['Dossiers', 'Etablissements', 'Avis', another_champ_repetition.libelle_for_export, champ_repetition.libelle_for_export])
        end
      end

      context 'with empty repetition' do
        before do
          dossiers.flat_map { |dossier| dossier.champs_public.filter(&:repetition?) }.each do |champ|
            champ.champs.destroy_all
          end
        end

        it 'should not have data' do
          expect(repetition_sheet).to be_nil
        end
      end
    end
  end

  describe 'to_zip' do
    subject { service.to_zip }
    context 'without files' do
      it 'does not raises in_batches' do
        expect { subject }.not_to raise_error(NoMethodError)
      end

      it 'returns an empty blob' do
        expect(subject).to be_an_instance_of(ActiveStorage::Blob)
      end
    end

    context 'generate_dossier_export' do
      it 'include_infos_administration (so it includes avis, champs privés)' do
        expect(ActiveStorage::DownloadableFile).to receive(:create_list_from_dossiers).with(anything, with_champs_private: true, include_infos_administration: true).and_return([])
        subject
      end
    end

    context 'with files (and http calls)' do
      let!(:dossier) { create(:dossier, :accepte, :with_populated_champs, :with_individual, procedure: procedure) }
      let(:dossier_exports) { PiecesJustificativesService.generate_dossier_export(Dossier.where(id: dossier)) }
      before do
        allow_any_instance_of(ActiveStorage::Attachment).to receive(:url).and_return("https://opengraph.githubassets.com/d0e7862b24d8026a3c03516d865b28151eb3859029c6c6c2e86605891fbdcd7a/socketry/async-io")
      end

      it 'returns a blob with valid files' do
        VCR.use_cassette('archive/new_file_to_get_200') do
          subject

          File.write('tmp.zip', subject.download, mode: 'wb')
          File.open('tmp.zip') do |fd|
            files = ZipTricks::FileReader.read_zip_structure(io: fd)
            structure = [
              "#{service.send(:base_filename)}/",
              "#{service.send(:base_filename)}/dossier-#{dossier.id}/",
              "#{service.send(:base_filename)}/dossier-#{dossier.id}/pieces_justificatives/",
              "#{service.send(:base_filename)}/dossier-#{dossier.id}/#{ActiveStorage::DownloadableFile.timestamped_filename(ActiveStorage::Attachment.where(record_type: "Champ").first)}",
              "#{service.send(:base_filename)}/dossier-#{dossier.id}/#{ActiveStorage::DownloadableFile.timestamped_filename(dossier_exports.first.first)}"
            ]
            expect(files.size).to eq(structure.size)
            expect(files.map(&:filename)).to match_array(structure)
          end
          FileUtils.remove_entry_secure('tmp.zip')
        end
      end
    end
  end

  describe 'to_geo_json' do
    subject do
      service
        .to_geo_json
        .open { |f| JSON.parse(f.read) }
    end

    let(:dossier) { create(:dossier, :en_instruction, :with_populated_champs, :with_individual, procedure: procedure) }
    let(:champ_carte) { dossier.champs_public.find(&:carte?) }
    let(:properties) { subject['features'].first['properties'] }

    before do
      create(:geo_area, :polygon, champ: champ_carte)
    end

    it 'should have features' do
      expect(subject['features'].size).to eq(1)
      expect(properties['dossier_id']).to eq(dossier.id)
      expect(properties['champ_id']).to eq(champ_carte.stable_id)
      expect(properties['champ_label']).to eq(champ_carte.libelle)
    end
  end
end
