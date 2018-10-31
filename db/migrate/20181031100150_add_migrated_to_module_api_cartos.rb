class AddMigratedToModuleAPICartos < ActiveRecord::Migration[5.2]
  def change
    add_column :module_api_cartos, :migrated, :boolean
  end
end
