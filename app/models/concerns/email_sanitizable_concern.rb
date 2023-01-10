module EmailSanitizableConcern
  extend ActiveSupport::Concern

  def sanitize_email(attribute)
    value_to_sanitize = self.send(attribute)
    if value_to_sanitize.present?
      self[attribute] = EmailSanitizer.sanitize(value_to_sanitize)
    end
  end

  class EmailSanitizer
    def self.sanitize(value)
      value.gsub(/[[:space:]]/, ' ').strip.downcase
    end
  end
end
