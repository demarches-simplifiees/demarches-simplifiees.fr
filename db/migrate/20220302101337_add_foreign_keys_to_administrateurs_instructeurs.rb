class AddForeignKeysToAdministrateursInstructeurs < ActiveRecord::Migration[6.1]
  def up
    # Sanity check
    say_with_time 'Removing AdministrateursInstructeur where the associated Administrateur no longer exists ' do
      deleted_administrateurs_ids = AdministrateursInstructeur.where.missing(:administrateur).pluck(:administrateur_id)
      AdministrateursInstructeur.where(administrateur_id: deleted_administrateurs_ids).delete_all
    end

    say_with_time 'Removing AdministrateursInstructeur where the associated Instructeur no longer exists ' do
      deleted_instructeurs_ids = AdministrateursInstructeur.where.missing(:instructeur).pluck(:instructeur_id)
      AdministrateursInstructeur.where(instructeur_id: deleted_instructeurs_ids).delete_all
    end

    add_foreign_key :administrateurs_instructeurs, :administrateurs
    add_foreign_key :administrateurs_instructeurs, :instructeurs
  end

  def down
    remove_foreign_key :administrateurs_instructeurs, :administrateurs
    remove_foreign_key :administrateurs_instructeurs, :instructeurs
  end
end
