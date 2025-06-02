# frozen_string_literal: true

class Champs::DatetimeChamp < Champ
  before_validation :convert_to_iso8601, unless: -> { validation_context == :prefill }
  validate :iso_8601

  def search_terms
    # Text search is pretty useless for datetimes so we’re not including these champs
  end

  private

  def convert_to_iso8601
    if (value =~ /=>/).present?
      self.value =
        begin
          hash_date = YAML.safe_load(value.gsub('=>', ': '))
          year, month, day, hour, minute = hash_date.values_at(1, 2, 3, 4, 5)
          Time.zone.local(year, month, day, hour, minute).iso8601
        rescue
          nil
        end
    elsif /^\d{2}\/\d{2}\/\d{4}\s\d{2}:\d{2}$/.match?(value) # old browsers can send with dd/mm/yyyy hh:mm format
      self.value = Time.zone.strptime(value, "%d/%m/%Y %H:%M").iso8601
    elsif /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}$/.match?(value)
      self.value = Time.zone.strptime(value, "%Y-%m-%d %H:%M").iso8601
    elsif valid_iso8601? # a correct iso8601 datetime
      self.value = Time.zone.strptime(value, "%Y-%m-%dT%H:%M").iso8601
    else
      self.value = nil
    end
  end

  def iso_8601
    return if valid_iso8601? || value.blank?
    # i18n-tasks-use t('errors.messages.not_a_datetime')
    errors.add :datetime, :not_a_datetime
  end

  def valid_iso8601?
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}[\+\-]\d{2}:\d{2})?$/.match?(value)
  end
end
