class WarnExpiringDossiersJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    expiring, expired = Dossier
      .includes(:procedure)
      .nearing_end_of_retention
      .partition(&:retention_expired?)

    AdministrationMailer.dossier_expiration_summary(expiring, expired).deliver_later
  end
end
