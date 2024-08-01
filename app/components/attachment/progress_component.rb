# frozen_string_literal: true

class Attachment::ProgressComponent < ApplicationComponent
  attr_reader :attachment
  attr_reader :ignore_antivirus

  def initialize(attachment:, ignore_antivirus: false)
    @attachment = attachment
    @ignore_antivirus = ignore_antivirus
  end

  def progress_label
    case
    when !ignore_antivirus && attachment.virus_scanner.pending?
      t(".antivirus_pending")
    when attachment.watermark_pending?
      t(".watermark_pending")
    end
  end

  def render?
    progress_label.present?
  end
end
