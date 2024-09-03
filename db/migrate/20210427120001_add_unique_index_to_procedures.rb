# frozen_string_literal: true

class AddUniqueIndexToProcedures < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    delete_duplicates :procedures, [:path, :closed_at, :hidden_at, :unpublished_at]
    add_concurrent_index :procedures, [:path, :closed_at, :hidden_at, :unpublished_at], name: 'procedure_path_uniqueness', unique: true
  end

  def down
    remove_index :procedures, [:path, :closed_at, :hidden_at, :unpublished_at], name: 'procedure_path_uniqueness'
  end
end
