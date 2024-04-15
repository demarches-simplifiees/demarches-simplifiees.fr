# frozen_string_literal: true

module Maintenance
  class MoveDolToColdStorageTask < MaintenanceTasks::Task
    attribute :start_text, :string
    validates :start_text, presence: true

    attribute :end_text, :string
    validates :end_text, presence: true

    def collection
      start_date = DateTime.parse(start_text)
      end_date = DateTime.parse(end_text)
      # Collection to be iterated over
      # Must be Active Record Relation or Array
      DossierOperationLog.where(created_at: start_date..end_date)
    end

    def process(dol)
      return if dol.data.nil?

      dol.move_to_cold_storage!
    end
  end
end
