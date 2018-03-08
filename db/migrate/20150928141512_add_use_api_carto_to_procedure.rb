class AddUseAPICartoToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :use_api_carto, :boolean, :default => false
  end
end
