# frozen_string_literal: true

class CreateProcedureLabels < ActiveRecord::Migration[7.0]
  def change
    create_table :procedure_labels do |t|
      t.string :name
      t.string :color
      t.references :procedure, null: false, foreign_key: true
      t.timestamps
    end
  end
end
