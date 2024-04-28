# frozen_string_literal: true

class AddAdministrateurForeignKeyToAdministrateursProcedure < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers

  def up
    delete_orphans :administrateurs_procedures, :administrateurs
    add_foreign_key :administrateurs_procedures, :administrateurs
  end

  def down
    remove_foreign_key :administrateurs_procedures, :administrateurs
  end
end
