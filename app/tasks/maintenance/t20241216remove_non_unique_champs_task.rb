# frozen_string_literal: true

module Maintenance
  class T20241216removeNonUniqueChampsTask < MaintenanceTasks::Task
    # Documentation: cette tâche supprime les champs en double dans un dossier

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Dossier.includes(champs: [])
    end

    def process(dossier)
      duplicated_champ_ids = dossier.champs.where(row_id: [Champ::NULL_ROW_ID, nil])
        .order(id: :desc)
        .select(:id, :stream, :stable_id, :row_id)
        .group_by { "#{_1.stream}-#{_1.public_id}" }
        .values
        .flat_map { _1[1..].map(&:id) }
      Dossier.transaction do
        if duplicated_champ_ids.present?
          Dossier.no_touching { dossier.champs.where(id: duplicated_champ_ids).destroy_all }
        end
        dossier.champs.where(row_id: nil).update_all(row_id: Champ::NULL_ROW_ID)
      end
    end
  end
end
