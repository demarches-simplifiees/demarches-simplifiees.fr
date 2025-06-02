# frozen_string_literal: true

class AddIndexToDeletedAtToDeletedDossiers < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers
  disable_ddl_transaction!
  def up
    add_concurrent_index :deleted_dossiers, :deleted_at
  end

  def down
    remove_index :deleted_dossiers, [:deleted_at]
  end
end
