# frozen_string_literal: true

module EmailHelper
  def status_color_code(status)
    if status.include?('delivered')
      return 'email-sent'
    elsif status.include?('blocked') || status.include?('hardBounces')
      return 'email-blocked'
    else
      return ''
    end
  end
end
