module EmailHelper
  def event_color_code(email_events)
    unique_events = email_events.map(&:event)
    if unique_events.include?('delivered')
      return 'email-sent'
    elsif unique_events.include?('blocked') || unique_events.include?('hardBounces')
      return 'email-blocked'
    else
      return ''
    end
  end
end
