class DownloadDossiersJob < ApplicationJob
  def perform(procedure, options, instructeur)
    dossiers = instructeur.dossiers.for_procedure(procedure)
    format = options[:format]
    options.delete(:format)

    case format
    when 'csv'
      filename = procedure.export_filename(:csv)
      data = procedure.to_csv(dossiers, options)
    when 'xlsx'
      filename = procedure.export_filename(:xlsx)
      data = procedure.to_xlsx(dossiers, options)
    when 'ods'
      filename = procedure.export_filename(:ods)
      data = procedure.to_ods(dossiers, options)
    end

    file_path = File.join('/tmp/', filename)
    IO.write(file_path, data)

    File.open(file_path) do |io|
      blob = ActiveStorage::Blob.create_after_upload!(
        io: io,
        filename: filename
      )

      InstructeurMailer.download_procedure(instructeur, procedure, blob).deliver_now
      File.delete(file_path)
    end
  end
end
