class StrictEmailValidator < ActiveModel::EachValidator
  # default devise email is : /\A[^@\s]+@[^@\s]+\z/
  #   saying that it's quite permissive
  #   but we want more, we want to ensure it's a domain with extension
  #   so we append \.[A-Za-z]{2,}
  REGEXP = /\A[^@\s]+@[^@\s\.]+\.[^@\s]{2,}\z/

  def validate_each(record, attribute, value)
    if value.present? && !regexp_for(record).match?(value)
      record.errors.add(attribute, :invalid_email_format)
    end
  end

  def regexp_for(record)
    if StrictEmailValidator.elligible_to_new_validation?(record)
      REGEXP
    else
      Devise.email_regexp
    end
  end

  def self.elligible_to_new_validation?(record)
    return false if !strict_validation_enabled?
    return false if (record.created_at || Time.zone.now) < date_since_strict_email_validation
    true
  end

  def self.strict_validation_enabled?
    ENV.key?('STRICT_EMAIL_VALIDATION_STARTS_AT')
  end

  def self.date_since_strict_email_validation
    DateTime.parse(ENV['STRICT_EMAIL_VALIDATION_STARTS_AT'])
  rescue
    DateTime.new(1789, 5, 5, 0, 0) # french revolution, ds was not yet launched
  end
end
