# frozen_string_literal: true

module Maintenance
  class SamsungBrowserIsSupportedTask < MaintenanceTasks::Task
    # Corrige une donnée si le navigateur utilisé
    # dans l’historique des Traitements des dossiers
    # 2024-02-21-01
    def collection
      Traitement.where(browser_name: 'Samsung Browser', browser_version: 12..)
    end

    def process(traitement)
      traitement.update_column(:browser_supported, true)
    end
  end
end
