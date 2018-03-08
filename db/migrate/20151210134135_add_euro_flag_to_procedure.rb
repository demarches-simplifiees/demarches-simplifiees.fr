class AddEuroFlagToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :euro_flag, :boolean, default: false
  end
end
