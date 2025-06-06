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
    if from_champ?
      attachment.record.libelle
    elsif from_messagerie?
      'Pièce jointe au message'
    elsif from_avis_externe?
      'Pièce jointe à l’avis'
    elsif from_justificatif_motivation?
      'Pièce jointe à la décision'
    end
  end

  def origin
    case
    when from_public_champ?
      'Dossier usager'
    when from_private_champ?
      'Annotation privée'
    when from_messagerie_expert?
      'Messagerie (expert)'
    when from_messagerie_instructeur?
      'Messagerie (instructeur)'
    when from_messagerie_usager?
      'Messagerie (usager)'
    when from_avis_externe_instructeur?
      'Avis externe (instructeur)'
    when from_avis_externe_expert?
      'Avis externe (expert)'
    when from_justificatif_motivation?
      'Justificatif de décision'
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
    from_public_champ? && updated_at > attachment.record.dossier.depose_at
  end

  def updated_at
    blob.created_at
  end

  def badge_updated_class
    class_names(
      "fr-badge fr-badge--sm" => true,
      # "highlighted" => seen_at.present? && updated_at&.>(seen_at)
      # we remove the hihlighting.
      # we let it commented because we want to test the reaction of instructors before deleting all the associated code
      "highlighted" => false
    )
  end

  private

  def from_champ?
    attachment.record.class.in?([Champs::PieceJustificativeChamp, Champs::TitreIdentiteChamp])
  end

  def from_public_champ?
    from_champ? && !attachment.record.private?
  end

  def from_private_champ?
    from_champ? && attachment.record.private?
  end

  def from_messagerie?
    attachment.record.is_a?(Commentaire)
  end

  def from_messagerie_instructeur?
    from_messagerie? && attachment.record.instructeur.present?
  end

  def from_messagerie_expert?
    from_messagerie? && attachment.record.expert.present?
  end

  def from_messagerie_usager?
    from_messagerie? && attachment.record.instructeur.nil? && attachment.record.expert.nil?
  end

  def from_avis_externe?
    attachment.record.is_a?(Avis)
  end

  def from_avis_externe_instructeur?
    from_avis_externe? && attachment.name == 'introduction_file'
  end

  def from_avis_externe_expert?
    from_avis_externe? && attachment.name == 'piece_justificative_file'
  end

  def from_justificatif_motivation?
    attachment.name == 'justificatif_motivation'
  end
end
