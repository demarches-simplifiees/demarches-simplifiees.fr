# frozen_string_literal: true

module Maintenance
  class ListChampsWithoutTypeTask < MaintenanceTasks::Task
    no_collection

    def process
      AdministrationMailer.list_champs_without_type.deliver_now
    end
  end
end
