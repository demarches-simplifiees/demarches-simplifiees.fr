# frozen_string_literal: true

module Maintenance
  class T20241202migrateNonFillableAndRepetitionChampsTask < MaintenanceTasks::Task
    # Documentation : cette tâche ajoute les représentations des rows sur les répétitions et supprime les champs sans valeurs

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Dossier.select(:id, :revision_id)
    end

    def process(dossier)
      # ici on peut faire un delete_all car les champs concernés n'ont pas de cascade
      Champ.where(dossier_id: dossier.id, type: ['Champs::HeaderSectionChamp', 'Champs::ExplicationChamp'])
        .or(Champ.where(dossier_id: dossier.id, type: 'Champs::RepetitionChamp', row_id: Champ::NULL_ROW_ID))
        .delete_all

      create_rows(dossier.id, dossier.revision_id)
    end

    def create_rows(dossier_id, revision_id)
      # les row_ids qui sont déjà persistés en base
      persisted_row_ids = Champs::RepetitionChamp.where(dossier_id:).where.not(row_id: Champ::NULL_ROW_ID).pluck(:row_id)

      first_child_stable_id_by_row_id = Champ.where(dossier_id:)
        .where.not(type: 'Champs::RepetitionChamp')
        .where.not(row_id: Champ::NULL_ROW_ID)
        .where.not(row_id: persisted_row_ids)
        .pluck(:row_id, :stable_id)
        .to_h

      return if first_child_stable_id_by_row_id.empty?

      coordinates_for_revision_id = ProcedureRevisionTypeDeChamp.joins(:type_de_champ).where(revision_id:)
      coordinates = coordinates_for_revision_id
        .where(types_de_champ: { type_champ: 'repetition' })
        .or(coordinates_for_revision_id.where.not(parent_id: nil))
        .pluck(:id, :stable_id, :parent_id, :private)
      coordinate_parent_id_by_stable_id = coordinates.index_by(&:second).transform_values(&:third)
      type_de_champ_attributes_by_id = coordinates.index_by(&:first).transform_values { { stable_id: _1.second, private: _1.last } }

      now = Time.zone.now
      row_attributes = { type: 'Champs::RepetitionChamp', created_at: now, updated_at: now, dossier_id:, stream: 'main' }
      new_rows = first_child_stable_id_by_row_id.filter_map do |row_id, child_stable_id|
        parent_id = coordinate_parent_id_by_stable_id[child_stable_id]
        type_de_champ_attributes = type_de_champ_attributes_by_id[parent_id]
        type_de_champ_attributes&.merge(row_id:, **row_attributes)
      end

      Champ.insert_all!(new_rows) if new_rows.present?
    end
  end
end
