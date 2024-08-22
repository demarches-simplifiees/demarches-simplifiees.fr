# frozen_string_literal: true

class CreateProcedureRevisionTypesDeChamp < ActiveRecord::Migration[5.2]
  def change
    create_table :procedure_revision_types_de_champ do |t|
      t.references :revision, null: false, index: true
      t.references :type_de_champ, foreign_key: true, null: false, index: true

      t.integer :position, null: false

      t.timestamps
    end

    add_foreign_key :procedure_revision_types_de_champ, :procedure_revisions, column: :revision_id
  end
end
