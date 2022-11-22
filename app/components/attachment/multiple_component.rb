# Display a widget for uploading, editing and deleting a file attachment
class Attachment::MultipleComponent < ApplicationComponent
  DEFAULT_MAX_ATTACHMENTS = 10

  renders_one :template

  attr_reader :champ
  attr_reader :attached_file
  attr_reader :user_can_download
  attr_reader :user_can_destroy
  attr_reader :max

  delegate :count, :empty?, to: :attachments, prefix: true

  def initialize(champ:, attached_file:, user_can_download: false, user_can_destroy: true, max: nil)
    @champ = champ
    @attached_file = attached_file
    @user_can_download = user_can_download
    @user_can_destroy = user_can_destroy
    @max = max || DEFAULT_MAX_ATTACHMENTS

    @attachments = attached_file.attachments || []
  end

  def each_attachment(&block)
    @attachments.each_with_index(&block)
  end

  def can_attach_next?
    @attachments.count < @max
  end

  def empty_component_id
    "attachment-multiple-empty-#{champ.id}"
  end

  def in_progress?
    @attachments.any? do
      attachment_in_progress?(_1)
    end
  end

  def in_progress_long?
    @attachments.any? do
      attachment_in_progress?(_1) && _1.created_at < 30.seconds.ago
    end
  end

  def poll_controller_options
    {
      controller: 'turbo-poll',
      turbo_poll_url_value: auto_attach_url
    }
  end

  def auto_attach_url
    helpers.auto_attach_url(champ)
  end

  private

  def attachments
    @attachments
  end

  def attachment_in_progress?(attachment)
    attachment.virus_scanner.pending? || attachment.watermark_pending?
  end
end
