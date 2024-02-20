# frozen_string_literal: true

module Maintenance
  class SamsungBrowserIsSupportedTask < MaintenanceTasks::Task
    def collection
      Traitement.where(browser_name: 'Samsung Browser', browser_version: 12..)
    end

    def process(traitement)
      traitement.update_column(:browser_supported, true)
    end
  end
end
