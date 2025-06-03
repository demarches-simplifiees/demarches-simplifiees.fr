# frozen_string_literal: true

module Maintenance
  class RotateAPIParticulierTokenEncryptionTask < MaintenanceTasks::Task
    def collection
      # rubocop:disable DS/Unscoped
      Procedure.unscoped.where.not(encrypted_api_particulier_token: nil)
      # rubocop:enable DS/Unscoped
    end

    def process(procedure)
      decrypted_token = procedure.api_particulier_token

      procedure.api_particulier_token = decrypted_token
      procedure.save!(validate: false)
    end

    def count
      collection.count
    end
  end
end
