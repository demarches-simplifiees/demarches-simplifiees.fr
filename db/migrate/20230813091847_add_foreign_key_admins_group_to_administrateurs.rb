class AddForeignKeyAdminsGroupToAdministrateurs < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :administrateurs, :admins_groups, validate: false
  end
end
