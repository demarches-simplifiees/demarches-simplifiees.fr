# frozen_string_literal: true

class Champs::DateChamp < Champ
  before_validation :convert_to_iso8601, unless: -> { validation_context == :prefill }
  validate :iso_8601
  validate :min_max_validation, if: :validate_champ_value?

  def min_max_validation
    return if value.blank?

    if type_de_champ.min.present? && Date.parse(value) < Date.parse(type_de_champ.min)
      errors.add(:value, :greater_than_or_equal_to, value: value, count: I18n.l(Date.parse(type_de_champ.min), format: :long))
    end
    if type_de_champ.max.present? && Date.parse(value) > Date.parse(type_de_champ.max)
      errors.add(:value, :less_than_or_equal_to, value: value, count: I18n.l(Date.parse(type_de_champ.max), format: :long))
    end
  end

  def search_terms
    # Text search is pretty useless for dates so we’re not including these champs
  end

  def formatted_value
    LexpolFieldsService.format_date(value)
  end

  private

  def convert_to_iso8601
    return if likely_iso8601_format? && parsable_iso8601?

    self.value = if /^\d{2}\/\d{2}\/\d{4}$/.match?(value)
      Date.parse(value).iso8601
    else
      nil
    end
  end

  def iso_8601
    return if parsable_iso8601? || value.blank?
    # i18n-tasks-use t('errors.messages.not_a_date')
    errors.add :date, :not_a_date
  end

  def likely_iso8601_format?
    /^\d{4}-\d{2}-\d{2}$/.match?(value)
  end

  def parsable_iso8601?
    Date.parse(value)
    true
  rescue ArgumentError, # case 2023-27-02, out of range
         TypeError # nil
    false
  end
end
