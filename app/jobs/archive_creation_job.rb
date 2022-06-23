class ArchiveCreationJob < ApplicationJob
  queue_as :archives

  def perform(procedure, archive, administrateur_or_instructeur)
    archive.restart! if archive.failed? # restart for AASM
    ProcedureArchiveService
      .new(procedure)
      .make_and_upload_archive(archive)
    archive.make_available!
    UserMailer.send_archive(administrateur_or_instructeur, procedure, archive).deliver_later
  rescue => e
    archive.fail! # fail for observability
    raise e       # re-raise for retryable behaviour
  end
end
