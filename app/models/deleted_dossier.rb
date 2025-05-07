# frozen_string_literal: true

class DeletedDossier < ApplicationRecord
  belongs_to :procedure, -> { with_discarded }, inverse_of: :deleted_dossiers, optional: false
  belongs_to :groupe_instructeur, inverse_of: :deleted_dossiers, optional: true

  scope :order_by_updated_at, -> (order = :desc) { order(created_at: order) }
  scope :deleted_since,       -> (since) { where(deleted_dossiers: { deleted_at: since.. }) }
  scope :state_termine,       -> { where(state: [states.fetch(:accepte), states.fetch(:refuse), states.fetch(:sans_suite)]) }

  enum :reason, {
    user_request:      'user_request',
    manager_request:   'manager_request',
    user_removed:      'user_removed',
    procedure_removed: 'procedure_removed',
    expired:           'expired',
    instructeur_request: 'instructeur_request',
    user_expired:      'user_expired'
  }

  enum :state, {
    en_construction: 'en_construction',
    en_instruction:  'en_instruction',
    accepte:         'accepte',
    refuse:          'refuse',
    sans_suite:      'sans_suite'
  }

  def self.create_from_dossier(dossier, reason)
    return if !dossier.log_operations?

    deleted_at = if dossier.hidden_by_user_at && dossier.en_construction?
      dossier.hidden_by_user_at
    else
      Time.current
    end

    # We have some bad data because of partially deleted dossiers in the past.
    # For now use find_or_create_by! to avoid errors.
    create_with(
      reason: reasons.fetch(reason),
      groupe_instructeur_id: dossier.groupe_instructeur_id,
      revision_id: dossier.revision_id,
      user_id: dossier.user_id,
      procedure: dossier.procedure,
      state: dossier.state,
      depose_at: dossier.depose_at,
      deleted_at:
    ).create_or_find_by!(dossier_id: dossier.id)
  end

  def procedure_removed?
    reason == self.class.reasons.fetch(:procedure_removed)
  end

  def user_locale
    User.find_by(id: user_id)&.locale || I18n.default_locale
  end
end
