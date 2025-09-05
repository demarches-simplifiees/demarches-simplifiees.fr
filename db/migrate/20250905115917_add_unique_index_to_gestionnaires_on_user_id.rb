# frozen_string_literal: true

class AddUniqueIndexToGestionnairesOnUserId < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :gestionnaires, :user_id, algorithm: :concurrently
    add_index :gestionnaires, :user_id, unique: true, algorithm: :concurrently
  end
end
