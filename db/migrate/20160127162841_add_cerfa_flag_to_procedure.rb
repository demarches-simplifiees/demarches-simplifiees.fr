class AddCerfaFlagToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :cerfa_flag, :boolean, :default => false
  end
end
