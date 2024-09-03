# frozen_string_literal: true

class AddMissingExportsInstructeurIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    if !index_exists?(:exports, :instructeur_id) # index may have already been added on other environments by a previous migration
      add_index :exports, :instructeur_id, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:exports, :instructeur_id)
      remove_index :exports, :instructeur_id
    end
  end
end
