# frozen_string_literal: true

module Maintenance
  class MoveDolToColdStorageTask < MaintenanceTasks::Task
    # Opération de rattrapage suite à un cron qui ne fonctionnait plus.
    # Permet de déplacer toutes les traces fonctionnelles (DossierOperationLog)
    # vers le stockage object plutot que de les conserver en BDD
    # 2024-04-15-01
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
