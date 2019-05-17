require "administrate/field/base"

class AttachmentField < Administrate::Field::Base
  def to_s
    data.filename.to_s
  end

  def blob_path
    Rails.application.routes.url_helpers.rails_blob_path(data)
  end
end
