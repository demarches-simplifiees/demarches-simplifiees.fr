class DropActiveColumnFromAdministrateurs < ActiveRecord::Migration[5.2]
  def change
    remove_column :administrateurs, :active
  end
end
