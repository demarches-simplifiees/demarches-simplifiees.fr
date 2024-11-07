# frozen_string_literal: true

class RdvService
  include Dry::Monads[:result]

  def initialize(user:)
    @user = user
  end

  def configure_rdv_binding(procedure:, enabled:)
    result = create_default_motif
    return result if result.failure?

    if enabled
      result = create_webhook
    else
      result = delete_webhook
    end

    result
  end

  def create_rdv(dossier:)
    Success({
      rdv: {
        id: 1,
        dossier_id: dossier&.id,
        details: "to be implemented"
      }
    })
  end

  def create_default_motif
    sleep(1) # Simulate API call
    Success({
      motif: {
        id: 1,
        name: "Motif par défaut"
      }
    })
  end

  def create_webhook
    sleep(1) # Simulate API call
    Success({
      webhook: {
        id: 1,
        name: "Webhook par défaut"
      }
    })
  end

  def delete_webhook
    Success({
      webhook: {
        id: 1,
        name: "Webhook par défaut"
      }
    })
  end
end
