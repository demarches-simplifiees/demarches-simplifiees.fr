# frozen_string_literal: true

class RdvService
  include Dry::Monads[:result]

  def create_rdv(dossier:)
    Success({
      rdv: {
        id: 1,
        dossier_id: dossier&.id,
        details: "to be implemented"
      }
    })
  end
end
