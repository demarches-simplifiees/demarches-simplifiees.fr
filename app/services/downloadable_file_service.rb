class DownloadableFileService
  ARCHIVE_CREATION_DIR = ENV.fetch('ARCHIVE_CREATION_DIR') { '/tmp' }

  def self.download_and_zip(procedure, attachments, filename, &block)
    Dir.mktmpdir(nil, ARCHIVE_CREATION_DIR) do |tmp_dir|
      export_dir = File.join(tmp_dir, filename)
      zip_path = File.join(ARCHIVE_CREATION_DIR, "#{filename}.zip")

      begin
        FileUtils.remove_entry_secure(export_dir) if Dir.exist?(export_dir)
        Dir.mkdir(export_dir)

        download_manager = DownloadManager::ProcedureAttachmentsExport.new(procedure, attachments, export_dir)
        download_manager.download_all

        Dir.chdir(tmp_dir) do
          File.delete(zip_path) if File.exist?(zip_path)
          system 'zip', '-0', '-r', zip_path, filename
        end
        yield(zip_path)
      ensure
        FileUtils.remove_entry_secure(export_dir) if Dir.exist?(export_dir)
        File.delete(zip_path) if File.exist?(zip_path)
      end
    end
  end
end
