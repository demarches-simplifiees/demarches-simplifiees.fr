require "administrate/field/base"

class AttachmentField < Administrate::Field::Base
  include ActionView::Helpers::NumberHelper
  def to_s
    "#{data.filename} (#{number_to_human_size(data.byte_size)})"
  end

  def blob_path
    Rails.application.routes.url_helpers.rails_blob_path(data)
  end
end
