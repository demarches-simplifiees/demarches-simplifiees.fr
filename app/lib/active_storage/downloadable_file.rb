class ActiveStorage::DownloadableFile
  def self.create_list_from_dossier(dossier, for_expert = false)
    dossier_export = PiecesJustificativesService.generate_dossier_export(dossier)
    pjs = [dossier_export] + PiecesJustificativesService.liste_documents(dossier, for_expert)
    pjs.map do |piece_justificative|
      [
        piece_justificative,
        "dossier-#{dossier.id}/#{self.timestamped_filename(piece_justificative)}"
      ]
    end
  end

  def self.create_list_from_dossiers(dossiers)
    dossiers.flat_map do |dossier|
      create_list_from_dossier(dossier)
    end
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
