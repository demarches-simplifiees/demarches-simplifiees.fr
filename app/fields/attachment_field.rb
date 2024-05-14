# frozen_string_literal: true

require "administrate/field/base"

class AttachmentField < Administrate::Field::Base
  include ActionView::Helpers::NumberHelper
  def to_s
    return "" if data.blank?

    "#{data.filename} (#{number_to_human_size(data.byte_size)})"
  end
end
