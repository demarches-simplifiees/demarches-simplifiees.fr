class UpdateModuleAPICarto < ActiveRecord::Migration

  class Procedure < ActiveRecord::Base

  end

  class ModuleAPICarto < ActiveRecord::Base

  end

  def up
    remove_column :module_api_cartos, :name
    add_index :module_api_cartos, [:procedure_id], unique: true

    add_column :module_api_cartos, :use_api_carto, :boolean, default: false
    add_column :module_api_cartos, :quartiers_prioritaires, :boolean, default: false
    add_column :module_api_cartos, :cadastre, :boolean, default: false

    Procedure.all.each do |procedure|
      module_api_carto = ModuleAPICarto.new(procedure_id: procedure.id)
      module_api_carto.use_api_carto = procedure.use_api_carto
      module_api_carto.quartiers_prioritaires = procedure.use_api_carto

      module_api_carto.save!
    end

    remove_column :procedures, :use_api_carto
  end

  def down
    add_column :procedures, :use_api_carto, :boolean, default: false
    remove_index :module_api_cartos, [:procedure_id]

    Procedure.all.each do |procedure|
      procedure.use_api_carto = ModuleAPICarto.find_by(procedure_id: procedure.id).use_api_carto
      procedure.save!
    end

    remove_column :module_api_cartos, :use_api_carto
    remove_column :module_api_cartos, :quartiers_prioritaires
    remove_column :module_api_cartos, :cadastre

    add_column :module_api_cartos, :name, :string

    ModuleAPICarto.destroy_all
  end
end
