# frozen_string_literal: true

class AddUniqueIndexToInstructeursOnUserId < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :instructeurs, :user_id, algorithm: :concurrently, if_exists: true
    add_index :instructeurs, :user_id, unique: true, algorithm: :concurrently
  end
end
