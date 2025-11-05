# frozen_string_literal: true

class Attachment::PendingPollComponent < ApplicationComponent
  attr_reader :attachments

  def initialize(poll_url:, attachment: nil, attachments: nil, context: nil)
    @poll_url = poll_url
    @attachments = if attachment.present?
      [attachment]
    else
      attachments
    end

    @context = context
  end

  def render?
    @attachments.any? { pending_attachment?(_1) }
  end

  def long_pending?
    @attachments.any? do
      pending_attachment?(_1) && _1.created_at < 60.seconds.ago
    end
  end

  def poll_controller_options
    {
      controller: 'turbo-poll',
      turbo_poll_url_value: @poll_url,
    }
  end

  def as_dossier?
    @context == :dossier
  end

  private

  def pending_attachment?(attachment)
    attachment.watermark_pending?
  end
end
