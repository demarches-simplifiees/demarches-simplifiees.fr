# frozen_string_literal: true

class Champs::DatetimeChamp < Champ
  validates_with DateLimitValidator, if: :validate_champ_value?
  before_validation :convert_to_iso8601, unless: -> { validation_context == :prefill }
  validate :iso_8601

  def search_terms
    # Text search is pretty useless for datetimes so we’re not including these champs
  end

  private

  def convert_to_iso8601
    self.value = DateDetectionUtils.convert_to_iso8601_datetime(value)
  end

  def iso_8601
    return if value.blank? || DateDetectionUtils.parsable_iso8601_datetime?(value)

    # i18n-tasks-use t('errors.messages.not_a_datetime')
    errors.add :datetime, :not_a_datetime
  end

  def valid_iso8601?
    DateDetectionUtils.likely_iso8601_datetime_format?(value) && DateDetectionUtils.parsable_iso8601_datetime?(value)
  end
end
