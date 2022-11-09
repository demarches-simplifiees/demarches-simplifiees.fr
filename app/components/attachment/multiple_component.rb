# Display a widget for uploading, editing and deleting a file attachment
class Attachment::MultipleComponent < ApplicationComponent
  renders_one :template

  attr_reader :form
  attr_reader :attached_file
  attr_reader :direct_upload
  attr_reader :id
  attr_reader :user_can_destroy
  attr_reader :max

  delegate :count, :empty?, to: :attachments, prefix: true

  def initialize(form:, attached_file:, user_can_destroy: false, direct_upload: true, id: nil, max: nil)
    @form = form
    @attached_file = attached_file
    @user_can_destroy = user_can_destroy
    @direct_upload = direct_upload
    @id = id
    @max = max || 10

    @attachments = attached_file.attachments || []
  end

  def champ
    form.object
  end

  def each_attachment(&block)
    @attachments.each_with_index(&block)
  end

  def can_attach_next?
    @attachments.count < @max
  end

  def empty_component_id
    "attachment-multiple-empty-#{form.object.id}"
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
    helpers.auto_attach_url(form.object)
  end

  private

  def attachments
    @attachments
  end

  def attachment_in_progress?(attachment)
    attachment.virus_scanner.pending? || attachment.watermark_pending?
  end
end
