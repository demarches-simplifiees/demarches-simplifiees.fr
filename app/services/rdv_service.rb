# frozen_string_literal: true

class RdvService
  include Dry::Monads[:result]

  def initialize(rdv_connection:)
    @rdv_connection = rdv_connection
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

  def send_rdv_invitation(dossier:, reason:)
    # Mock rdv creation

    rdv = Rdv.create!(
      starts_at: 7.days.from_now,
      dossier: dossier
    )

    Success({
      rdv:
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
