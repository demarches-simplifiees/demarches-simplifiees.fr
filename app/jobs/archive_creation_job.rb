class ArchiveCreationJob < ApplicationJob
  def perform(procedure, instructeur, type, month)
    ProcedureArchiveService.new(procedure).create_archive(instructeur, type, month)
  end
end
