# frozen_string_literal: true

module Maintenance
  class BackfillChampsStableIdTask < MaintenanceTasks::Task
    no_collection

    def process
      Migrations::BackfillStableIdJob.perform_later(0)
    end
  end
end
