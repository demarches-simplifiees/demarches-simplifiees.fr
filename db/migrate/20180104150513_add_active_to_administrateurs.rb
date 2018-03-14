class AddActiveToAdministrateurs < ActiveRecord::Migration[5.2]
  def change
    add_column :administrateurs, :active, :boolean, default: false
  end
end
