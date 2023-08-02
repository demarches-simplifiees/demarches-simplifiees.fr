class ArchiveCreationJob < ApplicationJob
  queue_as :archives

  before_perform do |job|
    Sentry.set_tags(procedure: job.arguments.first.id)
  end

  def max_run_time
    Archive::MAX_DUREE_GENERATION
  end

  def perform(procedure, archive, administrateur_or_instructeur)
    archive.compute_with_safe_stale_for_purge do
      ProcedureArchiveService
        .new(procedure)
        .make_and_upload_archive(archive)
      UserMailer.send_archive(administrateur_or_instructeur, procedure, archive).deliver_later
    end
  end
end
