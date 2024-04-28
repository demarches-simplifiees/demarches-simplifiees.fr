# frozen_string_literal: true

class NotificationService
  class << self
    SPREAD_DURATION = 2.hours

    def send_instructeur_email_notification
      instructeurs = Instructeur
        .includes(assign_to: [:procedure])
        .where(assign_tos: { daily_email_notifications_enabled: true })

      instructeurs.in_batches.each_record do |instructeur|
        data = instructeur.email_notification_data

        next if data.empty?

        wait = rand(0..SPREAD_DURATION)

        InstructeurMailer.send_notifications(instructeur, data).deliver_later(wait:)
      end
    end
  end
end
