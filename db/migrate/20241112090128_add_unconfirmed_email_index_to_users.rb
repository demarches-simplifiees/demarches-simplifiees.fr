# frozen_string_literal: true

class AddUnconfirmedEmailIndexToUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :users, :unconfirmed_email, algorithm: :concurrently
  end
end
