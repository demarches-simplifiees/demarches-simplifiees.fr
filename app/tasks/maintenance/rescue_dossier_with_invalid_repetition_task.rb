# frozen_string_literal: true

module Maintenance
  class RescueDossierWithInvalidRepetitionTask < MaintenanceTasks::Task
    INVALID_RELEASE_DATETIME = DateTime.new(2024, 8, 30, 12)
    def collection
      Dossier.where("last_champ_updated_at > ?", INVALID_RELEASE_DATETIME).pluck(:id) # heure de l'incident
    end

    def process(dossier_id)
      Dossier.find(dossier_id)
        .champs
        .filter { _1.row_id.present? && _1.parent_id.blank? }
        .each(&:destroy!)
    rescue ActiveRecord::RecordNotFound
      # some dossier had already been destroyed
    end

    def count
      # Optionally, define the number of rows that will be iterated over
      # This is used to track the task's progress
    end
  end
end
