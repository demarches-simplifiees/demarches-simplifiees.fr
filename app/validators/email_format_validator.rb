class EmailFormatValidator < ActiveModel::Validator
  def email_regex
    /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  end

  def validate(record)
    return if record.email.blank?
    record.errors[:base] << "Email invalide" if !email_regex.match(record.email)
  end
end
