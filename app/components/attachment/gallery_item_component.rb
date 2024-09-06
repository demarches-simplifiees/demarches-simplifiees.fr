# frozen_string_literal: true

class Attachment::GalleryItemComponent < ApplicationComponent
  include GalleryHelper
  attr_reader :attachment

  def initialize(attachment:)
    @attachment = attachment
  end

  def blob
    attachment.blob
  end

  def libelle
    attachment.record.class.in?([Champs::PieceJustificativeChamp, Champs::TitreIdentiteChamp]) ? attachment.record.libelle : 'Pièce jointe au message'
  end

  def title
    "#{libelle} -- #{sanitize(blob.filename.to_s)}"
  end
end
