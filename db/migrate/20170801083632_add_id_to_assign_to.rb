class AddIdToAssignTo < ActiveRecord::Migration[5.0]
  def change
    add_column :assign_tos, :id, :primary_key
  end
end
