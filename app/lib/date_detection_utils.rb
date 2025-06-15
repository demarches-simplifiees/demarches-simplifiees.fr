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

  # Détecte si la chaîne est exactement au format ISO8601 datetime (YYYY-MM-DDTHH:MM ou YYYY-MM-DDTHH:MM:SS+ZZ:ZZ)
  def self.likely_iso8601_datetime_format?(value)
    !!(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}([\+\-]\d{2}:\d{2})?)?$/.match?(value))
  end

  # Vérifie si la chaîne est un datetime ISO8601 parsable
  def self.parsable_iso8601_datetime?(value)
    Time.zone.parse(value)
    true
  rescue ArgumentError, TypeError
    false
  end

  # Convertit différents formats de datetime en ISO8601, sinon nil
  def self.convert_to_iso8601_datetime(value)
    return Time.zone.parse(value).iso8601 if likely_iso8601_datetime_format?(value) && parsable_iso8601_datetime?(value)
    if /^\d{2}\/\d{2}\/\d{4}\s\d{2}:\d{2}$/.match?(value)
      Time.zone.strptime(value, "%d/%m/%Y %H:%M").iso8601
    elsif /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}$/.match?(value)
      Time.zone.strptime(value, "%Y-%m-%d %H:%M").iso8601
    elsif value.is_a?(String) && value =~ /=>/
      begin
        hash_date = YAML.safe_load(value.gsub('=>', ': '))
        year, month, day, hour, minute = hash_date.values_at(1, 2, 3, 4, 5)
        Time.zone.local(year, month, day, hour, minute).iso8601
      rescue
        nil
      end
    else
      nil
    end
  rescue ArgumentError, TypeError
    nil
  end
end
