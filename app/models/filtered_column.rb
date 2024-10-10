# frozen_string_literal: true

class FilteredColumn
  include ActiveModel::Validations

  FILTERS_VALUE_MAX_LENGTH = 100
  # https://www.postgresql.org/docs/current/datatype-numeric.html
  PG_INTEGER_MAX_VALUE = 2147483647

  attr_reader :column, :filter

  delegate :label, to: :column

  validate :check_filter_max_length
  validate :check_filter_max_integer

  def initialize(column:, filter:)
    @column = column
    @filter = filter
  end

  private

  def check_filter_max_length
    if @filter.present? && @filter.length.to_i > FILTERS_VALUE_MAX_LENGTH
      errors.add(
        :base,
        "Le filtre #{label} est trop long (maximum: #{FILTERS_VALUE_MAX_LENGTH} caractères)"
      )
    end
  end

  def check_filter_max_integer
    if @column.column == 'id' && @filter.to_i > PG_INTEGER_MAX_VALUE
      errors.add(:base, "Le filtre #{label} n'est pas un numéro de dossier possible")
    end
  end
end
