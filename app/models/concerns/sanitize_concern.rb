module SanitizeConcern
  extend ActiveSupport::Concern

  def sanitize_uppercase(attribute)
    value_to_sanitize = self.send(attribute)
    if value_to_sanitize.present?
      self[attribute] = value_to_sanitize.gsub(/[[:space:]]/, ' ').strip.upcase
    end
  end

  def sanitize_camelcase(attribute)
    value_to_sanitize = self.send(attribute)
    if value_to_sanitize.present?
      self[attribute] = value_to_sanitize.gsub(/[[:space:]]/, ' ').strip.gsub(/(?<=[^[:alnum:]]|^)([[:alnum:]])([[:alnum:]]+)/) { "#{$1.capitalize}#{$2.downcase}" }
    end
  end
end
