# frozen_string_literal: true

class AddForeignKeysToAdministrateursInstructeurs < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers

  def up
    delete_orphans :administrateurs_instructeurs, :administrateurs
    add_foreign_key :administrateurs_instructeurs, :administrateurs

    delete_orphans :administrateurs_instructeurs, :instructeurs
    add_foreign_key :administrateurs_instructeurs, :instructeurs
  end

  def down
    remove_foreign_key :administrateurs_instructeurs, :administrateurs
    remove_foreign_key :administrateurs_instructeurs, :instructeurs
  end
end
