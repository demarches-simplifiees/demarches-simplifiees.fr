class Attachment::ProgressComponent < ApplicationComponent
  attr_reader :attachment

  def initialize(attachment:)
    @attachment = attachment
  end

  def progress_label
    case
    when attachment.virus_scanner.pending?
      t(".antivirus_pending")
    when attachment.watermark_pending?
      t(".watermark_pending")
    end
  end

  def render?
    progress_label.present?
  end
end
