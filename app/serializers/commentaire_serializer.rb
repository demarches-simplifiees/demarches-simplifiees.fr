# frozen_string_literal: true

class CommentaireSerializer < ActiveModel::Serializer
  attributes :email,
    :body,
    :created_at,
    :piece_jointe_attachments,
    :attachment

  def created_at
    object.created_at&.in_time_zone('UTC')
  end

  def attachment
    piece_jointe = object.piece_jointe_attachments.first

    if piece_jointe&.virus_scanner&.safe?
      Rails.application.routes.url_helpers.url_for(piece_jointe)
    end
  end
end
