# frozen_string_literal: true

class CreateProcedureRevisions < ActiveRecord::Migration[5.2]
  def change
    create_table :procedure_revisions do |t|
      t.references :procedure, foreign_key: true, null: false, index: true

      t.timestamps
    end

    add_column :dossiers, :revision_id, :bigint
    add_column :types_de_champ, :revision_id, :bigint
    add_column :procedures, :draft_revision_id, :bigint
    add_column :procedures, :published_revision_id, :bigint

    add_foreign_key :dossiers, :procedure_revisions, column: :revision_id
    add_foreign_key :types_de_champ, :procedure_revisions, column: :revision_id
    add_foreign_key :procedures, :procedure_revisions, column: :draft_revision_id
    add_foreign_key :procedures, :procedure_revisions, column: :published_revision_id

    add_index :dossiers, :revision_id
    add_index :types_de_champ, :revision_id
    add_index :procedures, :draft_revision_id
    add_index :procedures, :published_revision_id
  end
end
