# frozen_string_literal: true

# Run a virus scan on all attachments after they are analyzed.
#
# We're using a class extension to ensure that all attachments get scanned,
# regardless on how they were created. This could be an ActiveStorage::Analyzer,
# but as of Rails 6.1 only the first matching analyzer is ever run on
# a blob (and we may want to analyze the dimension of a picture as well
# as scanning it).
module AttachmentImageProcessorConcern
  extend ActiveSupport::Concern

  included do
    after_create_commit :process_image
  end

  private

  def process_image
    return if blob.nil?
    return if blob.attachments.size != 1
    return if blob.attachments.any? { _1.record_type == "Export" }
    return if !blob.content_type.in?(PROCESSABLE_TYPES)
    return if blob.byte_size.zero? # some empty files may be considered as image depending on filename

    ImageProcessorJob.perform_later(blob)
  end
end
