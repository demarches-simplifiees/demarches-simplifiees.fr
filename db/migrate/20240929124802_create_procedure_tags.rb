# frozen_string_literal: true

class CreateProcedureTags < ActiveRecord::Migration[7.0]
  def change
    create_table :procedure_tags do |t|
      t.string :name, null: false
      t.timestamps
    end

    add_index :procedure_tags, :name, unique: true
  end
end
