class AddAdministrateurForeignKeyToAdministrateursProcedure < ActiveRecord::Migration[6.1]
  def up
    # Sanity check
    say_with_time 'Removing AdministrateursProcedures where the associated Administrateur no longer exists ' do
      deleted_administrateur_ids = AdministrateursProcedure.where.missing(:administrateur).pluck(:administrateur_id)
      AdministrateursProcedure.where(administrateur_id: deleted_administrateur_ids).delete_all
    end

    add_foreign_key :administrateurs_procedures, :administrateurs
  end

  def down
    remove_foreign_key :administrateurs_procedures, :administrateurs
  end
end
