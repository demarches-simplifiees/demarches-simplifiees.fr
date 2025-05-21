# frozen_string_literal: true

class AddChampsNullsNotDistinctIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    StrongMigrations.lock_timeout = 0 # default is 10s
    add_index :champs, [:dossier_id, :stream, :stable_id, :row_id], unique: true, algorithm: :concurrently, nulls_not_distinct: true, name: 'index_champs_on_stream_and_public_id'
  end
end
