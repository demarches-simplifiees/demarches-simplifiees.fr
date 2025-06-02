# frozen_string_literal: true

class CreateGroupeInstructeurs < ActiveRecord::Migration[5.2]
  def change
    create_table :groupe_instructeurs do |t|
      t.references :procedure, foreign_key: true, null: false
      t.text :label, null: false

      t.timestamps
    end

    add_index :groupe_instructeurs, [:procedure_id, :label], unique: true
  end
end
