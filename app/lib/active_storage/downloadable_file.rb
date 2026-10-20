# frozen_string_literal: true

class ActiveStorage::DownloadableFile
  def self.create_list_from_dossiers(dossiers:, user_profile:, export_template: nil)
    pj_service = PiecesJustificativesService.new(user_profile:, export_template:)

    # The PDF of each dossier prints the static map of its carte champs;
    # without the preload it is one query per champ over the whole export.
    preloader = DossierPreloader.new(dossiers, includes_for_champ: [static_map_attachment: :blob])

    files = []
    preloader.in_batches(includes: DossierPreloader::PJ_EXPORT_INCLUDES) do |loaded_dossiers|
      files += pj_service.generate_dossiers_export(loaded_dossiers) + pj_service.liste_documents(loaded_dossiers)
    end

    files
  end

  def self.write_to_zip(zip, files)
    files.each do |file, path|
      zip.write_file(path) do |sink|
        if file.is_a?(ActiveStorage::FakeAttachment)
          IO.copy_stream(file.file, sink)
        else
          file.blob.download { sink << it }
        end
      end
    rescue ActiveStorage::FileNotFoundError
      next
    end
  end

  private

  def self.bill_and_path(bill)
    [
      bill,
      "bills/#{self.timestamped_filename(bill)}",
    ]
  end

  def self.pj_and_path(dossier_id, pj)
    [
      pj,
      "dossier-#{dossier_id}/#{self.timestamped_filename(pj)}",
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
    when 'Avis'
      'avis/'
    else
      'pieces_justificatives/'
    end
  end
end
