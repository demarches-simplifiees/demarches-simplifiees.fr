# == Schema Information
#
# Table name: email_events
#
#  id           :bigint           not null, primary key
#  method       :string           not null
#  processed_at :datetime
#  status       :string           not null
#  subject      :string           not null
#  to           :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class EmailEvent < ApplicationRecord
  enum status: {
    dispatched: 'dispatched',
    dispatch_error: 'dispatch_error'
  }

  scope :dolist, -> { where(method: 'dolist') }
  scope :sendinblue, -> { where(method: 'sendinblue') }

  class << self
    def create_from_message!(message, status:)
      to = message.to || ["unset"] # no recipients when error occurs *before* setting to: in the mailer

      to.each do |recipient|
        EmailEvent.create!(
          to: recipient,
          subject: message.subject || "",
          processed_at: message.date,
          method: ActionMailer::Base.delivery_methods.key(message.delivery_method.class),
          status:
        )
      rescue StandardError => error
        Sentry.capture_exception(error, extra: { subject: message.subject, status: })
      end
    end
  end

  def match_dolist_email
    return if to == "unset"

    # subjects does not match, so compare to event time with tolerance
    Dolist::API.new.sent_mails(to).sort_by(&:delivered_at).find { (processed_at..processed_at + 1.hour).cover?(_1.delivered_at) }
  end

  def domain
    to.split("@").last
  end
end
