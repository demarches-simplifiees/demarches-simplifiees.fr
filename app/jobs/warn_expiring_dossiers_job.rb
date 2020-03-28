class WarnExpiringDossiersJob < CronJob
  self.cron_expression = "0 0 1 * *"

  def perform(*args)
    expiring, expired = Dossier
      .en_instruction_close_to_expiration
      .partition(&:retention_expired?)

    AdministrationMailer.dossier_expiration_summary(expiring, expired).deliver_later
  end
end
