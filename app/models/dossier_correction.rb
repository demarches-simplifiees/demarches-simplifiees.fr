# frozen_string_literal: true

class DossierCorrection < ApplicationRecord
  belongs_to :dossier
  belongs_to :commentaire

  validates_associated :commentaire

  scope :pending, -> { where(resolved_at: nil) }

  enum reason: {
    incorrect: 'incorrect',
    incomplete: 'incomplete',
    outdated: 'outdated'
  }, _prefix: :dossier

  def resolved?
    resolved_at.present?
  end

  def resolve
    self.resolved_at = Time.current
  end

  def resolve!
    resolve
    save!
  end

  def pending? = !resolved?
end
