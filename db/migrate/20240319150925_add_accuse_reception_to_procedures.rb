class AddAccuseReceptionToProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :accuse_reception, :boolean, default: false, null: false
  end
end
