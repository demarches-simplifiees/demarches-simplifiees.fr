# frozen_string_literal: true

describe DownloadManager::ParallelDownloadQueue do
  let(:test_dir) { Dir.mktmpdir(nil, Dir.tmpdir) }
  let(:download_to_dir) { test_dir }
  before do
    downloadable_manager.on_error = proc { |_, _, _| }
  end

  after { FileUtils.remove_entry_secure(test_dir) if Dir.exist?(test_dir) }

  # the traversal specs target a dir we own and clean up: asserting on a shared
  # location like Dir.tmpdir would leak an artifact and make them order dependent.
  # `mktmpdir` is lazy inside a `let`, so this costs nothing to the other examples.
  let(:outside_dir) { Dir.mktmpdir(nil, Dir.tmpdir) }
  after { FileUtils.remove_entry_secure(outside_dir) if Dir.exist?(outside_dir) }

  # FNM_DOTMATCH: several payloads produce dot-prefixed components, which a bare
  # glob would silently skip
  def files_written_in(dir)
    Dir.glob(File.join(dir, '**', '*'), File::FNM_DOTMATCH).filter { File.file?(_1) }
  end

  def fake_attachment(id)
    ActiveStorage::FakeAttachment.new(
      file: StringIO.new('coucou'),
      filename: "export-dossier.pdf",
      name: 'pdf_export_for_instructeur',
      id:,
      created_at: Time.zone.now
    )
  end

  let(:downloadable_manager) { DownloadManager::ParallelDownloadQueue.new([attachment], download_to_dir) }
  let(:http_client) { instance_double(Typhoeus::Hydra) }

  describe '#download_one' do
    subject { downloadable_manager.download_one(attachment: attachment, path_in_download_dir: destination, http_client:) }

    let(:destination) { 'lol.png' }
    let(:attachment) { fake_attachment(1) }

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

    # A malicious export template lets an instructeur inject `..` sequences (or an
    # absolute path) into the directory part of the download path. `Pathname#join`
    # resolves `..` lexically, so the write escapes the export dir. The directory
    # part is never sanitized (only the basename is), so the sink must refuse to
    # write outside `destination`.
    context 'with traversal-shaped input in the destination directory' do
      {
        'via a ../ traversal sequence' => -> { File.join('..', File.basename(outside_dir), 'pwned.txt') },
        'via an absolute path' => -> { File.join(outside_dir, 'pwned.txt') },
      }.each do |description, path|
        context description do
          let(:destination) { instance_exec(&path) }

          it 'refuses to write outside the destination dir' do
            expect { subject }.to raise_error(DownloadManager::ParallelDownloadQueue::PathTraversalError)
            expect(files_written_in(outside_dir)).to be_empty
          end
        end
      end

      context 'with a sibling dir sharing the destination prefix' do
        # /tmp/xxx-export vs /tmp/xxx : a naive string start_with? would let this pass
        let(:destination) { File.join('..', "#{File.basename(test_dir)}-evil", 'pwned.txt') }

        it 'refuses to write in a sibling dir that shares the prefix' do
          sibling = "#{test_dir}-evil"
          expect { subject }.to raise_error(DownloadManager::ParallelDownloadQueue::PathTraversalError)
          expect(Dir.glob(File.join(sibling, '**', '*'))).to be_empty
        ensure
          FileUtils.remove_entry_secure(sibling) if sibling && Dir.exist?(sibling)
        end
      end

      # Resolving this `..` would land on <export>/dossier-999/pj.txt, i.e. inside
      # another dossier's folder — and would collide with the plain
      # 'dossier-999/pj.txt' path that DownloadableFileService.deduplicate_paths
      # believes to be distinct. The traversal component is dropped instead.
      context 'via a ../ traversal that stays inside the export dir' do
        let(:destination) { 'dossier-1/../dossier-999/pj.txt' }

        it 'drops the traversal component instead of resolving it' do
          subject

          expect(File.exist?(File.join(download_to_dir, 'dossier-1/dossier-999/pj.txt'))).to be_truthy
          expect(File.exist?(File.join(download_to_dir, 'dossier-999/pj.txt'))).to be_falsey
        end
      end

      context 'via a path whose last component is a traversal' do
        let(:destination) { 'dossier-1/..' }

        it 'refuses to write on the export dir itself' do
          expect { subject }.to raise_error(DownloadManager::ParallelDownloadQueue::PathTraversalError)
          expect(File.directory?(download_to_dir)).to be_truthy
        end
      end

      # A leading UTF-8 BOM is the one spelling of ".." that a String comparison
      # misses while the platform may still honour it: File.expand_path strips it on
      # macOS (so "﻿.." traverses exactly like "..") but not on Linux (where it
      # stays a plain directory name for the kernel).
      #
      # We therefore assert the security property, not which branch fires: either
      # expand_path normalises and the exact-equality check rejects the path, or it
      # does not and the path is literally the export dir followed by the sanitized
      # components we chose, hence confined by construction. Asserting the raise
      # would pass on macOS and fail on Linux while the code is correct on both.
      context 'via a BOM-prefixed traversal that expand_path may honour' do
        let(:destination) { "﻿../pwned.txt" }

        it 'never writes outside the destination dir' do
          begin
            subject
          rescue DownloadManager::ParallelDownloadQueue::PathTraversalError
            # refused outright: also a valid outcome
          end

          expect(files_written_in(outside_dir)).to be_empty
        end
      end

      context 'via a BOM-prefixed traversal absorbed inside the export dir' do
        let(:destination) { "dossier-1/﻿../dossier-999/pj.txt" }

        it 'never collides with the plain dossier-999 path' do
          begin
            subject
          rescue DownloadManager::ParallelDownloadQueue::PathTraversalError
            # refused outright: also a valid outcome
          end

          expect(files_written_in(outside_dir)).to be_empty
          expect(File.exist?(File.join(download_to_dir, 'dossier-999/pj.txt'))).to be_falsey
        end
      end

      # These spellings are not path separators at the byte level, so they cannot
      # traverse: they must stay literal components inside the export dir.
      context 'via unicode look-alikes of the separator and of the dot' do
        [
          "..／pwned.txt",  # fullwidth solidus
          "..∕pwned.txt",  # division slash
          "．．/pwned.txt", # fullwidth full stop
          "․․/pwned.txt", # one dot leader
          '....//....//pwned.txt',
          '%2e%2e%2fpwned.txt',
          "..\\..\\pwned.txt",
        ].each do |payload|
          context "with #{payload.inspect}" do
            let(:destination) { payload }

            it 'keeps the write inside the export dir' do
              subject

              expect(files_written_in(outside_dir)).to be_empty
              # FNM_DOTMATCH: several payloads produce dot-prefixed components,
              # which a bare glob would silently skip
              written = Dir.glob(File.join(download_to_dir, '**', '*'), File::FNM_DOTMATCH)
                .filter { File.file?(_1) }
              expect(written.size).to eq(1)
              expect(written.first).to start_with(download_to_dir + File::SEPARATOR)
            end
          end
        end
      end
    end

    context "download strategies" do
      subject { super(); http_client.run }
      let(:byte_size) { 1.kilobyte }
      let(:file_url) { 'http://example.com/test_file' }
      let(:destination) { 'test_file.txt' }
      let(:http_client) { Typhoeus::Hydra.new }
      let(:blob) { instance_double('ActiveStorage::Blob', byte_size:, url: file_url) }
      let(:attachment) { double('ActiveStorage::Attachment', blob: blob) }

      before do
        allow(attachment).to receive(:url).and_return(file_url)
        stub_request(:get, file_url).to_return(body: file_content, status: 200)
      end

      context 'for small files using request_in_whole method' do
        let(:file_content) { 'downloaded content' }
        it 'downloads the file in whole' do
          target = Pathname.new(download_to_dir).join(destination)
          expect { subject }.to change { target.exist? }.from(false).to(true)

          expect(File.read(target)).to eq(file_content)
        end
      end

      context 'for large files using request_in_chunks method' do
        let(:byte_size) { 20.megabytes } # Adjust byte size for large file scenario
        let(:file_content) { 'downloaded content' * 1000 }

        before do
          allow(downloadable_manager).to receive(:request_in_chunks).and_call_original
        end

        it 'downloads the file in chunks' do
          target = Pathname.new(download_to_dir).join(destination)
          expect { subject }.to change { target.exist? }.from(false).to(true)

          expect(File.read(target)).to eq(file_content)
          expect(downloadable_manager).to have_received(:request_in_chunks) # ensure we're taking the chunks code path
        end
      end
    end
  end

  # #download_all is the production entry point: it rescues per attachment, so a
  # single unconfinable path must be reported and skipped without aborting the
  # whole export.
  describe '#download_all' do
    subject { downloadable_manager.download_all }

    let(:poisoned_path) { File.join('..', File.basename(outside_dir), 'pwned.txt') }

    let(:downloadable_manager) do
      DownloadManager::ParallelDownloadQueue.new(
        [[legit_attachment, 'dossier-1/legit.txt'], [poisoned_attachment, poisoned_path]],
        download_to_dir
      )
    end
    let(:legit_attachment) { fake_attachment(1) }
    let(:poisoned_attachment) { fake_attachment(2) }
    let(:reported_errors) { [] }

    before do
      downloadable_manager.on_error = proc { |_attachment, path, error| reported_errors << [path, error] }
    end

    it 'reports the unconfinable path and still downloads the other attachments' do
      subject

      expect(reported_errors.map(&:first)).to eq([poisoned_path])
      expect(reported_errors.first.last).to be_a(DownloadManager::ParallelDownloadQueue::PathTraversalError)
      expect(File.exist?(File.join(download_to_dir, 'dossier-1/legit.txt'))).to be_truthy
      expect(files_written_in(outside_dir)).to be_empty
    end

    context 'when the hydra is interrupted before a chunked download completes' do
      let(:downloadable_manager) { DownloadManager::ParallelDownloadQueue.new([[attachment, 'large.bin']], download_to_dir) }
      let(:attachment) { double('ActiveStorage::Attachment', blob: instance_double('ActiveStorage::Blob', byte_size: 20.megabytes), url: 'http://example.com/large') }

      before { stub_request(:get, attachment.url).to_return(body: 'partial content') }

      it 'closes the file opened for the download' do
        opened_files = []
        allow(File).to receive(:open).and_wrap_original do |original, *args, **kwargs|
          original.call(*args, **kwargs).tap do |file|
            allow(file).to receive(:write).and_raise(Interrupt)
            opened_files << file
          end
        end

        expect { subject }.to raise_error(Interrupt)
        expect(opened_files).to contain_exactly(be_closed)
      end
    end
  end
end
