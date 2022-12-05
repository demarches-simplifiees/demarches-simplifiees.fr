class Attachment::PendingPollComponent < ApplicationComponent
  def initialize(poll_url:, attachment: nil, attachments: nil)
    @poll_url = poll_url
    @attachments = if attachment.present?
      [attachment]
    else
      attachments
    end
  end

  def render?
    @attachments.any? { pending_attachment?(_1) }
  end

  def long_pending?
    @attachments.any? do
      pending_attachment?(_1) && _1.created_at < 30.seconds.ago
    end
  end

  def poll_controller_options
    {
      controller: 'turbo-poll',
      turbo_poll_url_value: @poll_url
    }
  end

  private

  def pending_attachment?(attachment)
    attachment.virus_scanner.pending? || attachment.watermark_pending?
  end
end
