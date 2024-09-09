# frozen_string_literal: true

class Attachment::GalleryItemComponent < ApplicationComponent
  include GalleryHelper
  attr_reader :attachment

  def initialize(attachment:, gallery_demande: false)
    @attachment = attachment
    @gallery_demande = gallery_demande
  end

  def blob
    attachment.blob
  end

  def gallery_demande? = @gallery_demande

  def libelle
    attachment.record.class.in?([Champs::PieceJustificativeChamp, Champs::TitreIdentiteChamp]) ? attachment.record.libelle : 'Pièce jointe au message'
  end

  def title
    "#{libelle} -- #{sanitize(blob.filename.to_s)}"
  end

  def gallery_link(blob, &block)
    if displayable_image?(blob)
      link_to image_url(blob_url(attachment)), title: title, data: { src: blob.url }, class: 'gallery-link' do
        yield
      end
    elsif displayable_pdf?(blob)
      link_to blob.url, id: blob.id, data: { iframe: true, src: blob.url }, class: 'gallery-link', type: blob.content_type, title: title do
        yield
      end
    end
  end
end
