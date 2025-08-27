# frozen_string_literal: true

class AddUniqueIndexToAdministrateursOnUserId < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :administrateurs, :user_id, algorithm: :concurrently
    add_index :administrateurs, :user_id, unique: true, algorithm: :concurrently
  end
end
