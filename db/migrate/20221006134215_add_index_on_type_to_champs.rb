# frozen_string_literal: true

class AddIndexOnTypeToChamps < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers
  disable_ddl_transaction!
  def up
    add_concurrent_index :champs, [:type]
  end
end
