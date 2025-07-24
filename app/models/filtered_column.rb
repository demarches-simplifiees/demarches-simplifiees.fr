# frozen_string_literal: true

class FilteredColumn
  include ActiveModel::Validations

  FILTERS_VALUE_MAX_LENGTH = 4048
  # https://www.postgresql.org/docs/current/datatype-numeric.html
  PG_INTEGER_MAX_VALUE = 2147483647

  attr_reader :column, :filter, :or_filter

  delegate :label, to: :column

  validate :check_filter_max_length
  validate :check_filter_max_integer
  validates :filter, presence: {
    message: -> (object, _data) { "Le filtre « #{object.label} » ne peut pas être vide" }
  }, if: -> { or_filter.blank? }
  validates :or_filter, presence: {
    message: -> (object, _data) { "Le filtre « #{object.label} » ne peut pas être vide" }
  }, if: -> { filter.blank? }

  def initialize(column:, filter: nil, or_filter: nil)
    @column = column
    @filter = filter
    @or_filter = or_filter
  end

  def ==(other)
    other&.column == column && other.filter == filter && other.or_filter == or_filter
  end

  def id
    column.h_id.merge(filter:).merge(or_filter:).sort.to_json
  end

  private

  def check_filter_max_length
    if @filter.present? && @filter.length > FILTERS_VALUE_MAX_LENGTH
      errors.add(
        :base,
        "Le filtre « #{label} » est trop long (maximum: #{FILTERS_VALUE_MAX_LENGTH} caractères)"
      )
    end
  end

  def check_filter_max_integer
    if @column.column == 'id' && @filter.to_i > PG_INTEGER_MAX_VALUE
      errors.add(:base, "Le filtre « #{label} » n'est pas un numéro de dossier possible")
    end
  end
end
