class ValidateForeignKeyAdminsGroupToAdministrateurs < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :administrateurs, :admins_groups
  end
end
