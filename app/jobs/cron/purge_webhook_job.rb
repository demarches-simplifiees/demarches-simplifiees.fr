class Cron::PurgeWebhookJob < Cron::CronJob
  self.schedule_expression = "every day at 4 am"

  def perform(*args)
    WebhookEvent.delivered
      .expired
      .in_batches
      .destroy_all
  end
end
