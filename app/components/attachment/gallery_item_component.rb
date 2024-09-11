# frozen_string_literal: true

class Attachment::GalleryItemComponent < ApplicationComponent
  include GalleryHelper
  attr_reader :attachment, :seen_at

  def initialize(attachment:, gallery_demande: false, seen_at: nil)
    @attachment = attachment
    @gallery_demande = gallery_demande
    @seen_at = seen_at
  end

  def blob
    attachment.blob
  end

  def gallery_demande? = @gallery_demande

  def libelle
    from_dossier? ? attachment.record.libelle : 'Pièce jointe au message'
  end

  def from_dossier?
    attachment.record.class.in?([Champs::PieceJustificativeChamp, Champs::TitreIdentiteChamp])
  end

  def from_messagerie?
    attachment.record.is_a?(Commentaire)
  end

  def from_messagerie_instructeur?
    from_messagerie? && attachment.record.instructeur.present?
  end

  def from_messagerie_usager?
    from_messagerie? && attachment.record.instructeur.nil?
  end

  def origin
    case
    when from_dossier?
      'Dossier usager'
    when from_messagerie_instructeur?
      'Messagerie (instructeur)'
    when from_messagerie_usager?
      'Messagerie (usager)'
    end
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

  def created_at
    attachment.record.created_at
  end

  def updated?
    from_dossier? && updated_at > attachment.record.dossier.depose_at
  end

  def updated_at
    blob.created_at
  end

  def badge_updated_class
    class_names(
      "fr-badge fr-badge--sm" => true,
      "fr-badge--new" => seen_at.present? && updated_at&.>(seen_at)
    )
  end
end
