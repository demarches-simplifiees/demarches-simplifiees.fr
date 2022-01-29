class ActiveStorage::DownloadableFile
  # https://edgeapi.rubyonrails.org/classes/ActiveStorage/Blob.html#method-i-download
  def self.download(attachment:, destination_path:, in_chunk: true)
    byte_written = 0

    File.open(destination_path, mode: 'wb') do |fd| # we expact a path as string, so we can recreate the file (ex: failure/retry on former existing fd)
      if in_chunk
        attachment.download do |chunk|
          byte_written += fd.write(chunk)
        end
      else
        byte_written = fd.write(attachment.download)
      end
    end
    byte_written
  end

  def self.create_list_from_dossier(dossier, for_expert = false)
    pjs = PiecesJustificativesService.zip_entries(dossier, for_expert)
    pjs.map { |pj| [pj[0], "dossier-#{dossier.id}/" + pj[1]] }
  end

  private

  def self.timestamped_filename(attachment)
    # we pad the original file name with a timestamp
    # and a short id in order to help identify multiple versions and avoid name collisions
    folder = self.folder(attachment)
    extension = File.extname(attachment.filename.to_s)
    basename = File.basename(attachment.filename.to_s, extension)
    timestamp = attachment.created_at.strftime("%d-%m-%Y-%H-%M")
    id = attachment.id % 10000

    [folder, "#{basename}-#{timestamp}-#{id}#{extension}"].join
  end

  def self.folder(attachment)
    if attachment.name == 'pdf_export_for_instructeur'
      return ''
    end

    case attachment.record_type
    when 'Dossier'
      'dossier/'
    when 'DossierOperationLog', 'BillSignature'
      'horodatage/'
    when 'Commentaire'
      'messagerie/'
    else
      'pieces_justificatives/'
    end
  end

  def using_local_backend?
    [:local, :local_test, :test].include?(Rails.application.config.active_storage.service)
  end
end
