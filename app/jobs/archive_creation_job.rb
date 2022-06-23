class ArchiveCreationJob < ApplicationJob
  queue_as :archives

  def perform(procedure, archive, instructeur)
    archive.restart! if archive.failed? # restart for AASM
    ProcedureArchiveService
      .new(procedure)
      .make_and_upload_archive(archive)
    archive.make_available!
    InstructeurMailer.send_archive(instructeur, procedure, archive).deliver_later
  rescue => e
    archive.fail! # fail for observability
    raise e       # re-raise for retryable behaviour
  end
end
