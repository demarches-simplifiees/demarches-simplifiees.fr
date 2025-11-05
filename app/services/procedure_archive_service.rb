# frozen_string_literal: true

require 'tempfile'

class ProcedureArchiveService
  def initialize(procedure)
    @procedure = procedure
  end

  def make_and_upload_archive(archive)
    dossiers = Dossier.visible_by_administration
      .where(groupe_instructeur: archive.groupe_instructeurs)

    dossiers = if archive.time_span_type == 'everything'
      dossiers.state_termine
    else
      dossiers.processed_in_month(archive.month)
    end

    attachments = ActiveStorage::DownloadableFile.create_list_from_dossiers(dossiers:, user_profile: archive.user_profile)

    DownloadableFileService.download_and_zip(@procedure, attachments, zip_root_folder(archive)) do |zip_filepath|
      ArchiveUploader.new(procedure: @procedure, filename: archive.filename(@procedure), filepath: zip_filepath)
        .upload(archive)
    end
  end

  private

  def zip_root_folder(archive)
    zip_filename = archive.filename(@procedure)

    [
      File.basename(zip_filename, File.extname(zip_filename)),
      archive.id,
    ].join("-")
  end
end
