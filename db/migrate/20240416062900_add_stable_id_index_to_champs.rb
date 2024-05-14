# frozen_string_literal: true

class AddStableIdIndexToChamps < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :champs, :stable_id, algorithm: :concurrently
  end
end
