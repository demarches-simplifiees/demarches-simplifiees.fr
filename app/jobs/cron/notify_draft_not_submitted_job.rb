# frozen_string_literal: true

class Cron::NotifyDraftNotSubmittedJob < Cron::CronJob
  self.schedule_expression = "from monday through friday at 7 am"

  def perform(*args)
    Dossier.notify_draft_not_submitted
  end
end
