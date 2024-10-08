# frozen_string_literal: true

module Maintenance
  class UpdateAPIEntrepriseTokenExpiresAtTask < MaintenanceTasks::Task
    def collection
      Procedure.with_discarded.where.not(api_entreprise_token: nil)
    end

    def process(procedure)
      procedure.set_api_entreprise_token_expires_at
      procedure.save!
    end
  end
end
