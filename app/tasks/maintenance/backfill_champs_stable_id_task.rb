# frozen_string_literal: true

module Maintenance
  class BackfillChampsStableIdTask < MaintenanceTasks::Task
    attribute :limit, :integer
    no_collection

    def process
      Migrations::BackfillStableIdJob.perform_later(0, limit)
    end
  end
end
