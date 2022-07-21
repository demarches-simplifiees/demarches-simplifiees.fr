class AddManagerToAssignTos < ActiveRecord::Migration[6.1]
  def change
    add_column :assign_tos, :manager, :boolean
    change_column_default :assign_tos, :manager, default: false
  end
end
