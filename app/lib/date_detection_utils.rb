# frozen_string_literal: true

module DateDetectionUtils
  TIMESTAMP_STRING_REGEXP = /^[-+]?\d{10,13}(\.\d+)?$/
  TIMESTAMP_MIN = -2_208_988_800 # 1900-01-01 00:00:00 UTC
  TIMESTAMP_MAX = 4_102_444_800  # 2100-01-01 00:00:00 UTC
  TIMESTAMP_PROPERTY_REGEX = /(_at|date|datetime|timestamp|created|updated|expires)/i

  def self.should_suggest_timestamp_mapping?(value, property_name)
    return false unless property_name.to_s.match?(TIMESTAMP_PROPERTY_REGEX)

    value = convert_unix_timestamp(value)
    Integer(value).between?(TIMESTAMP_MIN, TIMESTAMP_MAX)
  rescue
    false
  end

  def self.likely_string_timestamp?(value)
    value.to_s.strip.match?(TIMESTAMP_STRING_REGEXP)
  end

  def self.convert_unix_timestamp(value)
    return nil if !likely_string_timestamp?(value)
    value.to_s.to_i
  end

  def self.parsable_iso8601_date?(value)
    begin
      Date.iso8601(value)
      true
    rescue Date::Error
      Date.strptime(value, "%Y/%m/%d") # Try parsing with a specific format
      true
    end
  rescue ArgumentError, TypeError
    false
  end

  def self.convert_to_iso8601_date(value)
    Date.parse(value).iso8601 if parsable_iso8601_date?(value)
  rescue
    nil
  end

  def self.parsable_iso8601_datetime?(value)
    value = convert_to_iso8601_datetime(value)
    value.present?
  rescue
    false
  end

  def self.convert_to_iso8601_datetime(value)
    if (value =~ /=>/).present?
      begin
        hash_date = YAML.safe_load(value.gsub('=>', ': '))
        year, month, day, hour, minute = hash_date.values_at(1, 2, 3, 4, 5)
        Time.zone.local(year, month, day, hour, minute).iso8601
      rescue
        nil
      end
    elsif /^\d{2}\/\d{2}\/\d{4}\s\d{2}:\d{2}$/.match?(value) # old browsers can send with dd/mm/yyyy hh:mm format
      Time.zone.strptime(value, "%d/%m/%Y %H:%M").iso8601
    elsif /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}$/.match?(value)
      Time.zone.strptime(value, "%Y-%m-%d %H:%M").iso8601
    elsif /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}[\+\-]\d{2}:\d{2})?$/.match?(value) # a correct iso8601 datetime
      Time.zone.strptime(value, "%Y-%m-%dT%H:%M").iso8601
    else
      nil
    end
  rescue
    nil
  end
end
