class Attachment::ShowComponent < ApplicationComponent
  def initialize(attachment:, user_can_upload: false)
    @attachment = attachment
    @user_can_upload = user_can_upload
  end

  attr_reader :attachment

  def user_can_upload?
    @user_can_upload
  end

  def should_display_link?
    (attachment.virus_scanner.safe? || !attachment.virus_scanner.started?) && !attachment.watermark_pending?
  end

  def attachment_path
    helpers.attachment_path(attachment.id, { signed_id: attachment.blob.signed_id, user_can_upload: user_can_upload? })
  end

  def poll_controller_options
    {
      controller: 'turbo-poll',
      turbo_poll_url_value: attachment_path
    }
  end
end
