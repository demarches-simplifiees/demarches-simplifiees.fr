class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::NumberHelper

  default from: "demarches-simplifiees.fr <#{I18n.t('dynamics.contact_email')}>"
  layout 'mailer'

  MAX_SIZE_EMAILABLE = 2.megabytes

  def add_attachment(name, content, description_for_error)
    if !content.present?
      return
    end

    if !emailable?(content)
      human_size = number_to_human_size(content.size)
      msg = "#{description_for_error} cannot be mailed because it is too large: #{human_size}"
      Raven.capture_message(msg, level: 'error')
      return
    end

    attachments[name] = content.read
  end

  def emailable?(attachment)
    attachment.size <= MAX_SIZE_EMAILABLE
  end
end
