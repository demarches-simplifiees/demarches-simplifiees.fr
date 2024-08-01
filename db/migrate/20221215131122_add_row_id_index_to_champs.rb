# frozen_string_literal: true

class AddRowIdIndexToChamps < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :champs, :row_id, algorithm: :concurrently
  end
end
