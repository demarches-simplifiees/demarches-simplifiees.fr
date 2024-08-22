# frozen_string_literal: true

class DolistReportJob < ApplicationJob
  # Consolidate random recent emails dispatched to Dolist with their statuses
  # and send a report by email.
  def perform(report_to, sample_size = 1000)
    events = EmailEvent.dolist.dispatched.where(processed_at: 2.weeks.ago..).order("RANDOM()").limit(sample_size)

    data = CSV.generate(headers: true) do |csv|
      column_names = ["dispatched_at", "subject", "domain", "status", "delivered_at", "delay (min)"]
      csv << column_names

      events.each do |event|
        report_event(csv, event)
      end
    end

    tempfile = Tempfile.new("dolist_report.csv")
    tempfile.write(data)
    tempfile.rewind

    SuperAdminMailer.dolist_report(report_to, tempfile.path).deliver_now
  ensure
    tempfile&.unlink
  end

  private

  def report_event(csv, event)
    wait_if_api_limit_reached

    sent_email = event.match_dolist_email

    delay = if sent_email
      (sent_email.delivered_at.to_i - event.processed_at.to_i) / 60
    end

    csv << [
      event.processed_at,
      event.subject,
      event.domain,
      sent_email&.status,
      sent_email&.delivered_at,
      delay
    ]
  rescue StandardError => error
    Sentry.capture_exception(error, extra: { event_id: event.id, api_limit_remaining: Dolist::API.limit_remaining, api_limit_reset_at: Dolist::API.limit_reset_at })
  end

  def wait_if_api_limit_reached
    return unless Dolist::API.near_rate_limit?

    Rails.logger.info("Dolist API rate limit reached, sleep until #{Dolist::API.limit_reset_at}")

    Dolist::API.sleep_until_limit_reset
  end
end
