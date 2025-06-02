# frozen_string_literal: true

class AddReferenceToExportsInstructeur < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    unless column_exists?(:exports, :instructeur_id)
      # Foreign key is added in a later migration
      add_reference :exports, :instructeur, null: true, default: nil, index: { algorithm: :concurrently }, foreign_key: false
    end
  end
end
