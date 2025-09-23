# frozen_string_literal: true

describe ProcedureArchiveService do
  let(:procedure) { build(:procedure) }
  let(:archive) { create(:archive) }
  let(:file) { Tempfile.new }
  let(:fixture_blob) { ActiveStorage::Blob.create_before_direct_upload!(filename: File.basename(file.path), byte_size: file.size, checksum: 'osf', content_type: 'text/plain') }

  let(:uploader) { ArchiveUploader.new(procedure: procedure, filename: archive.filename(procedure), filepath: file.path) }

  describe '.upload' do
    context 'when active storage service is local' do
      it 'uploads with upload_with_active_storage' do
        expect(uploader).to receive(:active_storage_service_local?).and_return(true)
        expect(uploader).to receive(:upload_with_active_storage).and_return(fixture_blob)
        uploader.upload(archive)
      end

      it 'link the created blob as an attachment to the current archive instance' do
        expect { uploader.upload(archive) }
          .to change { ActiveStorage::Attachment.where(name: 'file', record_type: 'Archive', record_id: archive.id).count }.by(1)
      end
    end

    context 'when active storage service is not local' do
      before do
        expect(uploader).to receive(:active_storage_service_local?).and_return(false)
        expect(File).to receive(:size).with(file.path).and_return(filesize)
      end

      context 'when file is smaller than MAX_FILE_SIZE_FOR_BACKEND_BEFORE_CHUNKING' do
        let(:filesize) { ArchiveUploader::MAX_FILE_SIZE_FOR_BACKEND_BEFORE_CHUNKING - 1 }

        it 'uploads with upload_with_active_storage' do
          expect(uploader).to receive(:upload_with_active_storage).and_return(fixture_blob)
          uploader.upload(archive)
        end
      end

      context 'when file is bigger than MAX_FILE_SIZE_FOR_BACKEND_BEFORE_CHUNKING' do
        let(:filesize) { ArchiveUploader::MAX_FILE_SIZE_FOR_BACKEND_BEFORE_CHUNKING + 1 }

        it 'uploads with upload_with_chunking_wrapper' do
          expect(uploader).to receive(:upload_with_chunking_wrapper).and_return(fixture_blob)
          uploader.upload(archive)
        end

        it 'link the created blob as an attachment to the current archive instance' do
          expect(uploader).to receive(:upload_with_chunking_wrapper).and_return(fixture_blob)
          expect { uploader.upload(archive) }
            .to change { ActiveStorage::Attachment.where(name: 'file', record_type: 'Archive', record_id: archive.id).count }.by(1)
        end
      end

      context 'when file was already attached to the archive' do
        let(:filesize) { ArchiveUploader::MAX_FILE_SIZE_FOR_BACKEND_BEFORE_CHUNKING + 1 }

        let(:archive) { create(:archive) }
        before do
          expect(uploader).to receive(:upload_with_chunking_wrapper).and_return(fixture_blob)
          archive.file.attach(fixture_file_upload(Rails.root.join('spec/fixtures/files/RIB.pdf'), 'text/plain'))
        end

        it 'purges the previous attachment' do
          expect(archive.file).to be_attached
          expect { uploader.upload(archive) }.not_to have_enqueued_job(DelayedPurgeJob)
        end
      end
    end
  end

  describe '.upload_with_chunking_wrapper' do
    let(:fake_blob_checksum) { Digest::SHA256.file(file.path) }
    let(:fake_blob_bytesize) { 100.gigabytes }

    before do
      expect(File).to receive(:size).with(file.path).and_return(fake_blob_bytesize)
      expect(Digest::SHA256).to receive(:file).with(file.path).and_return(double(hexdigest: fake_blob_checksum.hexdigest))
    end

    context 'when it just works' do
      it 'creates a blob' do
        expect(uploader).to receive(:syscall_to_custom_uploader).and_return(true)
        expect { uploader.send(:upload_with_chunking_wrapper) }
          .to change { ActiveStorage::Blob.where(checksum: fake_blob_checksum.hexdigest, byte_size: fake_blob_bytesize).count }.by(1)
      end
    end

    context 'when it fails once (DS proxy a bit flacky with archive ±>20Go, fails once, accept other call' do
      it 'retries' do
        expect(uploader).to receive(:syscall_to_custom_uploader).with(anything).once.and_raise(StandardError, "BOOM")
        expect(uploader).to receive(:syscall_to_custom_uploader).with(anything).once.and_return(true)
        expect { uploader.send(:upload_with_chunking_wrapper) }
          .to change { ActiveStorage::Blob.where(checksum: fake_blob_checksum.hexdigest, byte_size: fake_blob_bytesize).count }.by(1)
      end
    end

    context 'when it fails twice' do
      it 'does not retry more than once' do
        expect(uploader).to receive(:syscall_to_custom_uploader).with(anything).twice.and_raise(StandardError, "BOOM")
        expect { uploader.send(:upload_with_chunking_wrapper) }
          .to raise_error(RuntimeError, "custom archive attachment failed twice, retry later")
      end
    end
  end
end
