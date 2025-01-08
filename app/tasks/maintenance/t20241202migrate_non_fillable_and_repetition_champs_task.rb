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
        Champs::HeaderSectionChamp.where(dossier:).destroy_all
        Champs::ExplicationChamp.where(dossier:).destroy_all
        Champs::RepetitionChamp.where(dossier:, row_id: nil).destroy_all

        Dossier.transaction { create_rows(dossier) }
      end
    end

    def create_rows(dossier)
      repetitions = dossier.revision.types_de_champ.filter(&:repetition?)
      repetitions.each do |type_de_champ|
        stable_id = type_de_champ.stable_id
        row_ids = dossier.repetition_row_ids(type_de_champ)
        row_ids.each do |row_id|
          Champ.create_with(**type_de_champ.params_for_champ)
            .create_or_find_by!(dossier:, stable_id:, row_id:, stream: 'main')
        end
      end
    end
  end
end
