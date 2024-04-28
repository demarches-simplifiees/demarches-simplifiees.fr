# frozen_string_literal: true

class CommentaireGroupeGestionnaire < ApplicationRecord
  include Discard::Model
  belongs_to :groupe_gestionnaire
  belongs_to :gestionnaire, optional: true
  belongs_to :sender, polymorphic: true

  validates :body, presence: { message: "ne peut être vide" }

  before_create :set_emails

  def soft_deletable?(connected_user)
    sent_by?(connected_user) && sent_by_gestionnaire? && !discarded?
  end

  def soft_delete!
    discard!
  end

  def sent_by_gestionnaire?
    gestionnaire_id.present?
  end

  def sent_by_system?
    false
  end

  def sent_by?(someone)
    if gestionnaire
      someone == gestionnaire
    else
      someone == sender
    end
  end

  private

  def set_emails
    self.sender_email = sender.email
    self.gestionnaire_email = gestionnaire&.email
  end
end
