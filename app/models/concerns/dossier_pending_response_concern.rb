# frozen_string_literal: true

module DossierPendingResponseConcern
  extend ActiveSupport::Concern

  included do
    has_many :pending_responses, class_name: 'DossierPendingResponse', dependent: :destroy
    has_many :awaiting_responses, -> { DossierPendingResponse.pending }, class_name: 'DossierPendingResponse', inverse_of: :dossier
    has_one :awaiting_response, -> { DossierPendingResponse.pending }, class_name: 'DossierPendingResponse', inverse_of: :dossier

    scope :with_pending_responses, -> { joins(:pending_responses).where(pending_responses: { responded_at: nil }) }
  end

  def flag_as_pending_response!(commentaire)
    return if awaiting_responses.exists?

    pending_responses.create!(commentaire:)

    DossierNotification.create_notification(self, :attente_reponse)
  end

  def pending_response?
    return awaiting_responses.any? if awaiting_responses.loaded?

    awaiting_responses.exists?
  end

  def resolve_pending_response
    awaiting_response&.respond
  end

  def resolve_pending_response!
    resolve_pending_response
    awaiting_response&.save!

    awaiting_responses.reset
  end
end
