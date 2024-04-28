# frozen_string_literal: true

require "administrate/field/base"

class GeopointField < Administrate::Field::Base
  def lat
    data.first
  end

  def lng
    data.last
  end

  def present?
    lat.present? && lng.present?
  end
end
