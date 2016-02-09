class AddCerfaFlagToProcedure < ActiveRecord::Migration
  def change
    add_column :procedures, :cerfa_flag, :boolean, :default => false
  end
end
