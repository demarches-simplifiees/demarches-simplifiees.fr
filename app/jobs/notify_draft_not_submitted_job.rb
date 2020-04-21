class NotifyDraftNotSubmittedJob < CronJob
  self.cron_expression = "0 7 * * *"

  def perform(*args)
    Dossier.notify_draft_not_submitted
  end
end
