class AddEuroFlagToProcedure < ActiveRecord::Migration
  def change
    add_column :procedures, :euro_flag, :boolean, default: false
  end
end
