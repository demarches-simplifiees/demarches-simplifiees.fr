# frozen_string_literal: true

class CreateProcedurePaths < ActiveRecord::Migration[7.0]
  def change
    create_table :procedure_paths do |t|
      t.string :path
      t.datetime :deactivated_at
      t.references :procedure, null: false, foreign_key: true

      t.timestamps
    end
    add_index :procedure_paths, [:path, :deactivated_at], unique: true, where: "deactivated_at IS NULL"
  end
end
