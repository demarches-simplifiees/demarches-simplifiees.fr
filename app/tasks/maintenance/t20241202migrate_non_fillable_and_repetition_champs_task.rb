# frozen_string_literal: true

module Maintenance
  class T20241202migrateNonFillableAndRepetitionChampsTask < MaintenanceTasks::Task
    # Documentation : cette tâche ajoute les représentations des rows sur les répétitions et supprime les champs sans valeurs

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Dossier.includes(champs: [], revision: { revision_types_de_champ: { parent_type_de_champ: [], types_de_champ: [] }, types_de_champ_public: [], types_de_champ_private: [], types_de_champ: [] })
    end

    def process(dossier)
      Dossier.no_touching do
        champ_to_remove_ids = dossier
          .champs
          .filter { !_1.row? && (_1.repetition? || _1.header_section? || _1.explication?) }
          .map(&:id)
        dossier.champs.where(id: champ_to_remove_ids).destroy_all

        create_rows(dossier)
      end
    end

    def create_rows(dossier)
      repetitions = dossier.revision.types_de_champ.filter(&:repetition?)
      existing_row_ids = dossier.champs.filter(&:row?).to_set(&:row_id)
      now = Time.zone.now
      row_attributes = { created_at: now, updated_at: now, dossier_id: dossier.id }
      new_rows = repetitions.flat_map do |type_de_champ|
        row_ids = dossier.repetition_row_ids(type_de_champ).to_set - existing_row_ids
        row_ids.map { type_de_champ.params_for_champ.merge(row_id: _1, **row_attributes) }
      end
      Champ.insert_all!(new_rows) if new_rows.present?
    end
  end
end
