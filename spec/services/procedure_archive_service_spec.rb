describe ProcedureArchiveService do
  let(:procedure) { create(:procedure, :published) }
  let(:instructeur) { create(:instructeur) }
  let(:service) { ProcedureArchiveService.new(procedure) }
  let(:year) { 2020 }
  let(:month) { 3 }
  let(:date_month) { Date.strptime("#{year}-#{month}", "%Y-%m") }
  let(:groupe_instructeurs) { instructeur.groupe_instructeurs }

  before do
    procedure.defaut_groupe_instructeur.add(instructeur)
  end

  describe '#create_pending_archive' do
    context 'for a specific month' do
      it 'creates a pending archive' do
        archive = service.create_pending_archive(instructeur, 'monthly', date_month)

        expect(archive.time_span_type).to eq 'monthly'
        expect(archive.month).to eq date_month
        expect(archive.pending?).to be_truthy
      end
    end

    context 'for all months' do
      it 'creates a pending archive' do
        archive = service.create_pending_archive(instructeur, 'everything')

        expect(archive.time_span_type).to eq 'everything'
        expect(archive.month).to eq nil
        expect(archive.pending?).to be_truthy
      end
    end
  end

  describe '#make_and_upload_archive' do
    let!(:dossier) { create_dossier_for_month(year, month) }
    let!(:dossier_2020) { create_dossier_for_month(2020, month) }

    after { Timecop.return }

    context 'for a specific month' do
      let(:archive) { create(:archive, time_span_type: 'monthly', status: 'pending', month: date_month, groupe_instructeurs: groupe_instructeurs) }
      let(:year) { 2021 }

      it 'collects files with success' do
        allow_any_instance_of(ActiveStorage::Attachment).to receive(:url).and_return("https://opengraph.githubassets.com/d0e7862b24d8026a3c03516d865b28151eb3859029c6c6c2e86605891fbdcd7a/socketry/async-io")

        VCR.use_cassette('archive/new_file_to_get_200') do
          service.make_and_upload_archive(archive, instructeur)
        end

        archive.file.open do |f|
          files = ZipTricks::FileReader.read_zip_structure(io: f)

          structure = [
            "procedure-#{procedure.id}-#{archive.id}/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/pieces_justificatives/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/pieces_justificatives/attestation-dossier--05-03-2021-00-00-#{dossier.attestation.pdf.id % 10000}.pdf",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/export-#{dossier.id}-05-03-2021-00-00-#{dossier.id}.pdf"
          ]
          expect(files.map(&:filename)).to match_array(structure)
        end
        expect(archive.file.attached?).to be_truthy
      end

      it 'retry errors files with errors' do
        allow_any_instance_of(ActiveStorage::Attached::One).to receive(:url).and_return("https://www.demarches-simplifiees.fr/error_1")

        VCR.use_cassette('archive/new_file_to_get_400.html') do
          service.make_and_upload_archive(archive, instructeur)
        end
        archive.file.open do |f|
          files = ZipTricks::FileReader.read_zip_structure(io: f)
          structure = [
            "procedure-#{procedure.id}-#{archive.id}/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/pieces_justificatives/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/export-#{dossier.id}-05-03-2021-00-00-#{dossier.id}.pdf",
            "procedure-#{procedure.id}-#{archive.id}/LISEZMOI.txt"
          ]
          expect(files.map(&:filename)).to match_array(structure)
        end
        expect(archive.file.attached?).to be_truthy
      end

      context 'with a missing file' do
        let(:pj) do
          PiecesJustificativesService::FakeAttachment.new(
            file: StringIO.new('coucou'),
            filename: "export-dossier.pdf",
            name: 'pdf_export_for_instructeur',
            id: 1,
            created_at: Time.zone.now
          )
        end

        let(:bad_pj) do
          PiecesJustificativesService::FakeAttachment.new(
            file: nil,
            filename: "cni.png",
            name: 'cni.png',
            id: 2,
            created_at: Time.zone.now
          )
        end

        let(:documents) { [pj, bad_pj].map { |p| ActiveStorage::DownloadableFile.pj_and_path(dossier.id, p) } }
        before do
          allow(PiecesJustificativesService).to receive(:liste_documents).and_return(documents)
        end

        it 'collect files without raising exception' do
          expect { service.make_and_upload_archive(archive, instructeur) }.not_to raise_exception
        end

        it 'add bug report to archive' do
          service.make_and_upload_archive(archive, instructeur)

          archive.file.open do |f|
            zip_entries = ZipTricks::FileReader.read_zip_structure(io: f)
            structure = [
              "procedure-#{procedure.id}-#{archive.id}/",
              "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/",
              "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/export-dossier-05-03-2020-00-00-1.pdf",
              "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/pieces_justificatives/",
              "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/export-#{dossier.id}-05-03-2021-00-00-#{dossier.id}.pdf",
              "procedure-#{procedure.id}-#{archive.id}/LISEZMOI.txt"
            ]
            expect(zip_entries.map(&:filename)).to match_array(structure)
            zip_entries.map do |entry|
              next unless entry.filename == "procedure-#{procedure.id}-#{archive.id}/LISEZMOI.txt"
              extracted_content = ""
              extractor = entry.extractor_from(f)
              extracted_content << extractor.extract(1024 * 1024) until extractor.eof?
              expect(extracted_content).to match(/Impossible de .* .*cni.*png/)
            end
          end
        end
      end
    end

    context 'for all months' do
      let(:archive) { create(:archive, time_span_type: 'everything', status: 'pending', groupe_instructeurs: groupe_instructeurs) }

      it 'collect files' do
        allow_any_instance_of(ActiveStorage::Attachment).to receive(:url).and_return("https://opengraph.githubassets.com/5e61989aecb78e369c93674f877d7bf4ecde378850114a9563cdf8b6a2472536/typhoeus/typhoeus/issues/110")

        VCR.use_cassette('archive/old_file_to_get_200') do
          service.make_and_upload_archive(archive, instructeur)
        end

        archive = Archive.last
        archive.file.open do |f|
          files = ZipTricks::FileReader.read_zip_structure(io: f)
          structure = [
            "procedure-#{procedure.id}-#{archive.id}/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/pieces_justificatives/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/pieces_justificatives/attestation-dossier--05-03-2020-00-00-#{dossier.attestation.pdf.id % 10000}.pdf",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier.id}/export-#{dossier.id}-05-03-2020-00-00-#{dossier.id}.pdf",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier_2020.id}/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier_2020.id}/export-#{dossier_2020.id}-05-03-2020-00-00-#{dossier_2020.id}.pdf",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier_2020.id}/pieces_justificatives/",
            "procedure-#{procedure.id}-#{archive.id}/dossier-#{dossier_2020.id}/pieces_justificatives/attestation-dossier--05-03-2020-00-00-#{dossier_2020.attestation.pdf.id % 10000}.pdf"
          ]
          expect(files.map(&:filename)).to match_array(structure)
        end
        expect(archive.file.attached?).to be_truthy
      end
    end
  end

  describe '#download_and_zip' do
    let(:archive) { build(:archive, id: '3') }
    it 'create a tmpdir while block is running' do
      previous_dir_list = Dir.entries(ProcedureArchiveService::ARCHIVE_CREATION_DIR)

      service.send(:download_and_zip, archive, []) do |_zip_file|
        new_dir_list = Dir.entries(ProcedureArchiveService::ARCHIVE_CREATION_DIR)
        expect(previous_dir_list).not_to eq(new_dir_list)
      end
    end

    it 'cleans up its tmpdir after block execution' do
      expect { service.send(:download_and_zip, archive, []) { |zip_file| } }
        .not_to change { Dir.entries(ProcedureArchiveService::ARCHIVE_CREATION_DIR) }
    end

    it 'creates a zip with zip utility' do
      expected_zip_path = File.join(ProcedureArchiveService::ARCHIVE_CREATION_DIR, "#{service.send(:zip_root_folder, archive)}.zip")
      expect(service).to receive(:system).with('zip', '-0', '-r', expected_zip_path, an_instance_of(String))
      service.send(:download_and_zip, archive, []) { |zip_path| }
    end

    it 'cleans up its generated zip' do
      expected_zip_path = File.join(ProcedureArchiveService::ARCHIVE_CREATION_DIR, "#{service.send(:zip_root_folder, archive)}.zip")
      service.send(:download_and_zip, archive, []) do |_zip_path|
        expect(File.exist?(expected_zip_path)).to be_truthy
      end
      expect(File.exist?(expected_zip_path)).to be_falsey
    end
  end

  private

  def create_dossier_for_month(year, month)
    Timecop.freeze(Time.zone.local(year, month, 5))
    create(:dossier, :accepte, :with_attestation, procedure: procedure)
  end

  def extract(zip_file, zip_entry)
    extractor = zip_entry.extractor_from(zip_file)
    extractor.extract
  end
end
