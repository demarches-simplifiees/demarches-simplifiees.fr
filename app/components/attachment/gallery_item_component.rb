# frozen_string_literal: true

class Attachment::GalleryItemComponent < ApplicationComponent
  include GalleryHelper

  attr_reader :attachment
  delegate :blob, :record, to: :attachment

  def initialize(attachment:)
    @attachment = attachment
  end

  def libelle = record_libelle(record).truncate(30)

  def origin
    case record
    in Champ if record.public?
      'Dossier usager'
    in Champ if record.private?
      'Annotation privée'
    in Commentaire if record.instructeur.present?
      'Messagerie (instructeur)'
    in Commentaire if record.expert.present?
      'Messagerie (expert)'
    in Commentaire
      'Messagerie (usager)'
    in Avis if attachment.name == 'introduction_file'
      'Avis externe (instructeur)'
    in Avis if attachment.name == 'piece_justificative_file'
      'Avis externe (expert)'
    else
      if attachment.name == 'justificatif_motivation'
        'Justificatif de décision'
      end
    end
  end

  def updated?
    record.is_a?(Champ) && record.public? && updated_at > record.dossier.depose_at
  end

  def updated_at
    blob.created_at
  end
end
