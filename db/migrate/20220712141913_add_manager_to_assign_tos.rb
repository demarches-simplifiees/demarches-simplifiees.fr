class AddManagerToAssignTos < ActiveRecord::Migration[6.1]
  def up
    add_column :assign_tos, :manager, :boolean
    change_column_default :assign_tos, :manager, false
  end

  def down
    remove_column :assign_tos, :manager
  end
end
