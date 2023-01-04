# Preview all emails at http://localhost:3000/rails/mailers/devise_user_mailer
class DeviseUserMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  helper MailerHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  layout 'mailers/layout'

  # Don’t retry to send a message if the server rejects the recipient address
  rescue_from Net::SMTPSyntaxError do |_error|
    message.perform_deliveries = false
  end

  rescue_from Net::SMTPServerBusy do |error|
    if /unexpected recipients/.match?(error.message)
      message.perform_deliveries = false
    end
  end

  def template_paths
    ['devise_mailer']
  end

  def confirmation_instructions(record, token, opts = {})
    opts[:from] = NO_REPLY_EMAIL
    @procedure = opts[:procedure_after_confirmation] || nil
    @prefill_token = opts[:prefill_token]
    super
  end
end
