# frozen_string_literal: true

class StrictEmailValidator < ActiveModel::EachValidator
  # default devise email is : /\A[^@\s]+@[^@\s]+\z/
  #   saying that it's quite permissive
  #   but we want more, we want to ensure it's a domain with extension
  #   so we append \.[A-Za-z]{2,}
  TRUEMAIL_REGEX_DOMAIN = /[\p{L}0-9]+([-.]{1}[\p{L}\p{N}\p{Pd}]*[\p{L}\p{N}]+)*\.\p{L}{2,63}/i.freeze
  TRUEMAIL_REGEX_EMAIL_PATTERN = %r{(?=\A.{6,255}\z)(\A([\p{L}0-9]+[\w\p{L}.+!~,'&%#*^`{}|\-/?=$]*)@(#{TRUEMAIL_REGEX_DOMAIN})\z)}.freeze

  REGEXP = TRUEMAIL_REGEX_EMAIL_PATTERN

  DATE_SINCE_STRICT_EMAIL_VALIDATION = Date.parse(ENV.fetch('STRICT_EMAIL_VALIDATION_STARTS_ON')) rescue 0

  def validate_each(record, attribute, value)
    if value.present? && !regexp_for(record).match?(value)
      record.errors.add(attribute, :invalid_email_format)
    end
  end

  def regexp_for(record)
    if StrictEmailValidator.eligible_to_new_validation?(record)
      REGEXP
    else
      Devise.email_regexp
    end
  end

  def self.eligible_to_new_validation?(record)
    return false if !strict_validation_enabled?
    return false if (record.created_at || Time.zone.now) < DATE_SINCE_STRICT_EMAIL_VALIDATION
    true
  end

  def self.strict_validation_enabled?
    ENV.key?('STRICT_EMAIL_VALIDATION_STARTS_ON')
  end
end
