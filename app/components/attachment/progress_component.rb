class Attachment::ProgressComponent < ApplicationComponent
  attr_reader :attachment

  def initialize(attachment:)
    @attachment = attachment
  end

  def progress_label
    case
    when attachment.virus_scanner.pending?
      "Analyse antivirus en cours…"
    when attachment.watermark_pending?
      "Traitement en cours…"
    end
  end

  def render?
    progress_label.present?
  end
end
