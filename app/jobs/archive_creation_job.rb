class ArchiveCreationJob < ApplicationJob
  queue_as :exports

  def perform(procedure, archive, instructeur)
    ProcedureArchiveService
      .new(procedure)
      .collect_files_archive(archive, instructeur)
  end
end
