# frozen_string_literal: true

class AddExternalIdIndexToChamps < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_index :champs, :external_id
  end

  def down
    remove_index :champs, column: :external_id
  end
end
