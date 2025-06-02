# frozen_string_literal: true

# Request a watermark on files attached to a `Champs::TitreIdentiteChamp`.
#
# We're using a class extension here, but we could as well have a periodic
# job that watermarks relevant attachments.
module AttachmentTitreIdentiteWatermarkConcern
  extend ActiveSupport::Concern

  included do
    after_create_commit :watermark_later
  end

  private

  def watermark_later
    blob&.watermark_later
  end
end
