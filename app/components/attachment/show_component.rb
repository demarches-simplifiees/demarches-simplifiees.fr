class Attachment::ShowComponent < ApplicationComponent
  def initialize(attachment:)
    @attachment = attachment
  end

  attr_reader :attachment

  def should_display_link?
    (attachment.virus_scanner.safe? || !attachment.virus_scanner.started?) && !attachment.watermark_pending?
  end

  def error_message
    case
    when attachment.virus_scanner.infected?
      "Virus détecté, le téléchargement est bloqué."
    when attachment.virus_scanner.corrupt?
      "Le fichier est corrompu, le téléchargement est bloqué."
    end
  end

  def error?
    attachment.virus_scanner_error?
  end
end
