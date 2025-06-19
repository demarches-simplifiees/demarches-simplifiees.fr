# frozen_string_literal: true

class Champs::DatetimeChamp < Champ
  validates_with DateLimitValidator, if: :validate_champ_value?
  before_validation :convert_to_iso8601_datetime, unless: -> { validation_context == :prefill }
  validate :iso_8601

  def search_terms
    # Text search is pretty useless for datetimes so we’re not including these champs
  end

  private

  def convert_to_iso8601_datetime
    self.value = DateDetectionUtils.convert_to_iso8601_datetime(value)
  end

  def iso_8601
    return if DateDetectionUtils.parsable_iso8601_datetime?(value) || value.blank?

    # i18n-tasks-use t('errors.messages.not_a_datetime')
    errors.add :datetime, :not_a_datetime
  end
end
