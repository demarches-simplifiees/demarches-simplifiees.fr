# frozen_string_literal: true

class CreateExpertsProcedures < ActiveRecord::Migration[6.0]
  def change
    create_table :experts_procedures do |t|
      t.references :expert, null: false, foreign_key: true
      t.references :procedure, null: false, foreign_key: true
      t.boolean :allow_decision_access, default: false, null: false

      t.timestamps
    end
  end
end
