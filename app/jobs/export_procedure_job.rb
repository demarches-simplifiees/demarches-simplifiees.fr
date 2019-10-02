class ExportProcedureJob < ApplicationJob
  def perform(procedure, instructeur, export_format)
    dossiers = instructeur.dossiers.for_procedure(procedure)
    options = { :version => 'v2', :tables => [:dossiers, :etablissements] }

    case export_format
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
      # todo: add a TTL to the uploaded file, even though it's checked for in the controller too
      procedure.export_file = ActiveStorage::Blob.create_after_upload!(
        io: io,
        filename: filename
      )

      InstructeurMailer.download_procedure_export(instructeur, procedure).deliver_now
      File.delete(file_path)
    end
  end
end
