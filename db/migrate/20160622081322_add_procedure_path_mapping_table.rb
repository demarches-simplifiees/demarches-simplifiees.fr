class AddProcedurePathMappingTable < ActiveRecord::Migration
  class ProcedurePath < ApplicationRecord
  end

  def change
    create_table :procedure_paths do |t|
      t.string :path, limit: 30, null: true, unique: true, index: true
      t.integer :procedure_id, unique: true, null: true
      t.integer :administrateur_id, unique: true, null: true
    end
    add_foreign_key :procedure_paths, :procedures
    add_foreign_key :procedure_paths, :administrateurs

    Procedure.all.each do |procedure|
      ProcedurePath.create(path: (procedure.id).to_s, procedure_id: procedure.id, administrateur_id: procedure.administrateur.id)
    end
  end
end
