# frozen_string_literal: true

class AddIndexToUserssOnLastSignInAt < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :users, :last_sign_in_at, algorithm: :concurrently
  end
end
