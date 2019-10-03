class ExportProcedureJob < ApplicationJob
  def perform(procedure, instructeur, export_format)
    procedure.prepare_export_download(export_format)
    InstructeurMailer.notify_procedure_export_available(instructeur, procedure, export_format).deliver_later
  end
end
