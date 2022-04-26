class ActiveStorage::DownloadableFile
  def self.create_list_from_dossiers(dossiers, for_expert = false)
    PiecesJustificativesService.generate_dossier_export(dossiers) +
      PiecesJustificativesService.liste_documents(dossiers, for_expert)
  end

  private

  def self.bill_and_path(bill)
    [
      bill,
      "bills/#{self.timestamped_filename(bill)}"
    ]
  end

  def self.pj_and_path(dossier_id, pj)
    [
      pj,
      "dossier-#{dossier_id}/#{self.timestamped_filename(pj)}"
    ]
  end

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
end
