class WarnExpiringDossiersJob < CronJob
  self.schedule_expression = "every 1 month at midnight"

  def perform(*args)
    expiring, expired = Dossier
      .en_instruction_close_to_expiration
      .partition(&:retention_expired?)

    AdministrationMailer.dossier_expiration_summary(expiring, expired).deliver_later
  end
end
