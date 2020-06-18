class CreateProcedureRevisions < ActiveRecord::Migration[5.2]
  def change
    create_table :procedure_revisions do |t|
      t.references :procedure, foreign_key: true, null: false

      t.timestamps
    end

    add_column :dossiers, :procedure_revision_id, :bigint
    add_column :types_de_champ, :procedure_revision_id, :bigint
    add_column :procedures, :draft_revision_id, :bigint
    add_column :procedures, :published_revision_id, :bigint
  end
end
