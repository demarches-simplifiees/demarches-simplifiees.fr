# frozen_string_literal: true

class DossierPendingResponse < ApplicationRecord
  belongs_to :dossier
  belongs_to :commentaire

  validates_associated :commentaire

  scope :pending, -> { where(responded_at: nil) }

  def responded?
    responded_at.present?
  end

  def respond
    self.responded_at = Time.current
    destroy_attente_reponse_notification
  end

  def respond!
    respond
    save!
  end

  def pending? = !responded?
end

private

def destroy_attente_reponse_notification
  DossierNotification.destroy_notifications_by_dossier_and_type(dossier, :attente_reponse)
end
