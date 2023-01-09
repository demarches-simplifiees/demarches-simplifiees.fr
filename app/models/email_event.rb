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
    dispatched: 'dispatched'
  }
  class << self
    def create_from_message!(message, status:)
      message.to.each do |recipient|
        EmailEvent.create!(
          to: pseudonymize_email(recipient),
          subject: message.subject,
          processed_at: message.date,
          method: ActionMailer::Base.delivery_methods.key(message.delivery_method.class),
          status:
        )
      rescue StandardError => error
        Sentry.capture_exception(error, extra: { subject: message.subject, status: })
      end
    end

    def pseudonymize_email(email)
      username, domain_name = email.split("@")

      username_masked = if username.length > 3
        username[0..1] + "*" * (username.length - 3) + username[-1]
      else
        "*" * username.length
      end

      "#{username_masked}@#{domain_name}"
    end
  end
end
