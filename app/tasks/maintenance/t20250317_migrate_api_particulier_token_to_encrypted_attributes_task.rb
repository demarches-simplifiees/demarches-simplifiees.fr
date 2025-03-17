# frozen_string_literal: true

module Maintenance
  class T20250317MigrateAPIParticulierTokenToEncryptedAttributesTask < MaintenanceTasks::Task
    # Documentation: migre les API particulier token d'une implémentation custom d'attributs chiffrés
    # vers les encrypted attributs standard de Rails

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    run_on_first_deploy

    def collection
      Procedure.where.not(encrypted_api_particulier_token: nil)
    end

    def process(element)
      old_token = EncryptionService.new.decrypt(element.encrypted_api_particulier_token)

      element.update_columns(api_particulier_token: old_token, encrypted_api_particulier_token: nil)
    end

    def count
      collection.count
    end
  end
end
