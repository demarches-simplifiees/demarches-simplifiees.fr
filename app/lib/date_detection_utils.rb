# frozen_string_literal: true

module DateDetectionUtils
  def self.parsable_iso8601_date?(value)
    Date.parse(value)
    true
  rescue ArgumentError, TypeError
    false
  end

  def self.convert_to_iso8601_date(value)
    Date.parse(value).iso8601 if parsable_iso8601_date?(value)
  rescue
    nil
  end
end
