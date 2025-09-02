# frozen_string_literal: true

class AddUniqueIndexToExpertsOnUserId < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :experts, :user_id, algorithm: :concurrently
    add_index :experts, :user_id, unique: true, algorithm: :concurrently
  end
end
