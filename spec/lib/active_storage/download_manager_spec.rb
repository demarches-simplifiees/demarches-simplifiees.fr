describe ActiveStorage::DownloadManager do
  let(:test_dir) { Dir.mktmpdir(nil, Dir.tmpdir) }
  let(:download_to_dir) { test_dir }
  after { FileUtils.remove_entry_secure(test_dir) if Dir.exist?(test_dir) }

  let(:downloadable_manager) { ActiveStorage::DownloadManager.new(download_to_dir: download_to_dir) }

  describe '#download_one' do
    subject { downloadable_manager.download_one(attachment: attachment, path_in_download_dir: path_in_download_dir, async_internet: double) }

    let(:path_in_download_dir) { 'lol.png' }
    let(:attachment) do
      PiecesJustificativesService::FakeAttachment.new(
        file: StringIO.new('coucou'),
        filename: "export-dossier.pdf",
        name: 'pdf_export_for_instructeur',
        id: 1,
        created_at: Time.zone.now
      )
    end

    context 'with a PiecesJustificativesService::FakeAttachment and it works' do
      it 'write attachment.file to disk' do
        target = File.join(download_to_dir, path_in_download_dir)
        expect { subject }.to change { File.exist?(target) }
        attachment.file.rewind
        expect(attachment.file.read).to eq(File.read(target))
        expect(downloadable_manager.errors).not_to have_key(path_in_download_dir)
      end
    end

    context 'with a PiecesJustificativesService::FakeAttachment and it fails' do
      it 'write attachment.file to disk' do
        expect(attachment.file).to receive(:read).and_raise("boom")
        target = File.join(download_to_dir, path_in_download_dir)
        expect { subject }.to raise_error(StandardError)
        expect(File.exist?(target)).to be_falsey
        expect(downloadable_manager.errors).to have_key(path_in_download_dir)
      end
    end
  end
end
