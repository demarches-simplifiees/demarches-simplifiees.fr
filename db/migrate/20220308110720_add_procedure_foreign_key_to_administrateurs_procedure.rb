# frozen_string_literal: true

class AddProcedureForeignKeyToAdministrateursProcedure < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers

  def up
    delete_orphans :administrateurs_procedures, :procedures
    add_foreign_key :administrateurs_procedures, :procedures
  end

  def down
    remove_foreign_key :administrateurs_procedures, :procedures
  end
end
