# frozen_string_literal: true

module DateDetectionUtils
  # Détecte si la chaîne est exactement au format ISO8601 date (YYYY-MM-DD)
  def self.likely_iso8601_date_format?(value)
    !!(/^\d{4}-\d{2}-\d{2}$/.match?(value))
  end

  # Vérifie si la chaîne est une date ISO8601 parsable
  def self.parsable_iso8601_date?(value)
    Date.parse(value)
    true
  rescue ArgumentError, TypeError
    false
  end

  # Convertit une date au format dd/mm/yyyy en ISO8601, sinon nil
  def self.convert_to_iso8601(value)
    return value if likely_iso8601_date_format?(value) && parsable_iso8601_date?(value)
    if /^\d{2}\/\d{2}\/\d{4}$/.match?(value)
      Date.parse(value).iso8601
    else
      nil
    end
  rescue ArgumentError, TypeError
    nil
  end
end
