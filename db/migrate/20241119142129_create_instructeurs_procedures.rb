# frozen_string_literal: true

class CreateInstructeursProcedures < ActiveRecord::Migration[7.0]
  def change
    create_table :instructeurs_procedures do |t|
      t.references :instructeur, null: false, foreign_key: true
      t.references :procedure, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end

    add_index :instructeurs_procedures, [:instructeur_id, :procedure_id], unique: true, name: 'index_instructeurs_procedures_on_instructeur_and_procedure'
  end
end
