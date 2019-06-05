module ServiceHelper
  def formatted_horaires(horaires)
    horaires.sub(/\S/, &:downcase)
  end

  def email_for_reply_to(service)
    if service && service&.email =~ URI::MailTo::EMAIL_REGEXP
      [service.email, CONTACT_EMAIL]
    end
  end
end
