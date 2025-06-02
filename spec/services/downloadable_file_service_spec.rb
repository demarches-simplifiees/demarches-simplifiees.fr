# frozen_string_literal: true

describe DownloadableFileService do
  let(:procedure) { create(:procedure, :published) }
  let(:service) { ProcedureArchiveService.new(procedure) }

  before do
    FileUtils.mkdir_p('/tmp/test_archive_creation')
    stub_const("DownloadableFileService::ARCHIVE_CREATION_DIR", '/tmp/test_archive_creation')
  end

  describe '#download_and_zip' do
    let(:archive) { build(:archive, id: '3') }
    let(:filename) { service.send(:zip_root_folder, archive) }

    it 'create a tmpdir while block is running' do
      previous_dir_list = Dir.entries(DownloadableFileService::ARCHIVE_CREATION_DIR)

      DownloadableFileService.download_and_zip(procedure, [], filename) do |_zip_file|
        new_dir_list = Dir.entries(DownloadableFileService::ARCHIVE_CREATION_DIR)
        expect(previous_dir_list).not_to eq(new_dir_list)
      end
    end

    it 'cleans up its tmpdir after block execution' do
      expect { DownloadableFileService.download_and_zip(procedure, [], filename) { |zip_file| } }
        .not_to change { Dir.entries(DownloadableFileService::ARCHIVE_CREATION_DIR) }
    end

    it 'creates a zip with zip utility' do
      expected_zip_path = File.join(DownloadableFileService::ARCHIVE_CREATION_DIR, "#{service.send(:zip_root_folder, archive)}.zip")
      expect(DownloadableFileService).to receive(:system).with('zip', '-0', '-r', expected_zip_path, an_instance_of(String))
      DownloadableFileService.download_and_zip(procedure, [], filename) { |zip_path| }
    end

    it 'cleans up its generated zip' do
      expected_zip_path = File.join(DownloadableFileService::ARCHIVE_CREATION_DIR, "#{service.send(:zip_root_folder, archive)}.zip")
      DownloadableFileService.download_and_zip(procedure, [], filename) do |_zip_path|
        expect(File.exist?(expected_zip_path)).to be_truthy
      end
      expect(File.exist?(expected_zip_path)).to be_falsey
    end
  end
end
