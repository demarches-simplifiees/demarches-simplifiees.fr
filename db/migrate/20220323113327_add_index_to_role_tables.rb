# frozen_string_literal: true

class AddIndexToRoleTables < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :administrateurs, :user_id, algorithm: :concurrently
    add_index :instructeurs, :user_id, algorithm: :concurrently
    add_index :experts, :user_id, algorithm: :concurrently
  end
end
