# frozen_string_literal: true

class AddUniqueIndexToIndividuals < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    delete_duplicates :individuals, [:dossier_id]
    remove_index :individuals, [:dossier_id]
    add_concurrent_index :individuals, [:dossier_id], unique: true
  end

  def down
    remove_index :individuals, [:dossier_id], unique: true
    add_concurrent_index :individuals, [:dossier_id]
  end
end
