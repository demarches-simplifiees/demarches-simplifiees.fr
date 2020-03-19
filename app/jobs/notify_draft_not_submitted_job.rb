class NotifyDraftNotSubmittedJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Dossier.notify_draft_not_submitted
  end
end
