module EmailSanitizableConcern
  extend ActiveSupport::Concern

  def sanitize_email(attribute)
    value_to_sanitize = self.send(attribute)
    if value_to_sanitize.present?
      self[attribute] = value_to_sanitize.gsub(/[[:space:]]/, ' ').strip.downcase
    end
  end
end
