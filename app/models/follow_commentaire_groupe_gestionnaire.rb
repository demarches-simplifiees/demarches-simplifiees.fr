# frozen_string_literal: true

class FollowCommentaireGroupeGestionnaire < ApplicationRecord
  belongs_to :gestionnaire
  belongs_to :groupe_gestionnaire
  belongs_to :sender, polymorphic: true, optional: true

  validates :gestionnaire_id, uniqueness: { scope: [:groupe_gestionnaire_id, :sender_id, :sender_type, :unfollowed_at] }
end
