# frozen_string_literal: true

class RemoveExportsUnicityConstraint < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    remove_index :exports, ["format", "time_span_type", "statut", "key"], unique: true

    add_index :exports, "key", unique: false, algorithm: :concurrently
  end
end
