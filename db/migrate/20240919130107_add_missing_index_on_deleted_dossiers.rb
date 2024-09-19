# frozen_string_literal: true

class AddMissingIndexOnDeletedDossiers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :deleted_dossiers, :user_id, algorithm: :concurrently
  end
end
