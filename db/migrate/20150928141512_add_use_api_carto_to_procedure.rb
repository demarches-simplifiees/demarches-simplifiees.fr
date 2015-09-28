class AddUseAPICartoToProcedure < ActiveRecord::Migration
  def change
    add_column :procedures, :use_api_carto, :boolean, :default => false
  end
end
