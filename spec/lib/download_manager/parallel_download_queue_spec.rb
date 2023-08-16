describe DownloadManager::ParallelDownloadQueue do
  let(:test_dir) { Dir.mktmpdir(nil, Dir.tmpdir) }
  let(:download_to_dir) { test_dir }
  before do
    downloadable_manager.on_error = proc { |_, _, _| }
  end

  after { FileUtils.remove_entry_secure(test_dir) if Dir.exist?(test_dir) }

  let(:downloadable_manager) { DownloadManager::ParallelDownloadQueue.new([attachment], download_to_dir) }
  describe '#download_one' do
    subject { downloadable_manager.download_one(attachment: attachment, path_in_download_dir: destination, http_client: double) }

    let(:destination) { 'lol.png' }
    let(:attachment) do
      ActiveStorage::FakeAttachment.new(
        file: StringIO.new('coucou'),
        filename: "export-dossier.pdf",
        name: 'pdf_export_for_instructeur',
        id: 1,
        created_at: Time.zone.now
      )
    end

    context 'with a ActiveStorage::FakeAttachment and it works' do
      it 'write attachment.file to disk' do
        target = File.join(download_to_dir, destination)
        expect { subject }.to change { File.exist?(target) }
        attachment.file.rewind
        expect(attachment.file.read).to eq(File.read(target))
      end
    end

    context 'with a ActiveStorage::FakeAttachment and it fails' do
      it 'write attachment.file to disk' do
        expect(attachment.file).to receive(:read).and_raise("boom")
        target = File.join(download_to_dir, destination)
        expect { subject }.to raise_error(StandardError)
        expect(File.exist?(target)).to be_falsey
        # expect(downloadable_manager.errors).to have_key(destination)
      end
    end

    context 'with a destination filename too long' do
      let(:destination) { 'a' * 252 + '.txt' }

      it 'limit the file path to 255 bytes' do
        target = File.join(download_to_dir, 'a' * 251 + '.txt')
        expect { subject }.to change { File.exist?(target) }
        attachment.file.rewind
        expect(attachment.file.read).to eq(File.read(target))
      end
    end

    context 'with filename containing unsafe characters for storage' do
      let(:destination) { "file:éà\u{202e} K.txt" }

      it 'sanitize the problematic chars' do
        target = File.join(download_to_dir, 'file-éà- K.txt')
        expect { subject }.to change { File.exist?(target) }
        attachment.file.rewind
        expect(attachment.file.read).to eq(File.read(target))
      end

      context 'with a destination tree' do
        let(:destination) { 'subdir/file.txt' }

        it 'preserves the destination tree' do
          target = File.join(download_to_dir, 'subdir/file.txt')
          expect { subject }.to change { File.exist?(target) }
          attachment.file.rewind
          expect(attachment.file.read).to eq(File.read(target))
        end
      end
    end
  end
end
