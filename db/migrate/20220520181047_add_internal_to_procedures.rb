class AddInternalToProcedures < ActiveRecord::Migration[6.1]
  def up
    add_column :procedures, :internal, :boolean
    change_column_default :procedures, :internal, false
  end

  def down
    remove_column :procedures, :internal
  end
end
