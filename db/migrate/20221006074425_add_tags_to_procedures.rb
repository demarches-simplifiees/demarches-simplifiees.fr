# frozen_string_literal: true

class AddTagsToProcedures < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  def change
    # we have a small number of procedure so it must go smoothly
    safety_assured do
      add_column :procedures, :tags, :text, array: true, default: []
      add_index :procedures, :tags, using: 'gin', algorithm: :concurrently
    end
  end
end
