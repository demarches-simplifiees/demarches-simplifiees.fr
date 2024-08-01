# frozen_string_literal: true

require "administrate/field/base"

class IdField < Administrate::Field::Number
  def to_s
    return "" if data.nil?
    return data.ids.map { format(_1) }.join(", ") if data.respond_to?(:ids)

    format(data.id)
  end

  private

  def format(id)
    "##{id}"
  end
end
