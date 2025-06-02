# frozen_string_literal: true

class AddUniqueIndexToInvites < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    delete_duplicates :invites, [:email, :dossier_id]
    add_concurrent_index :invites, [:email, :dossier_id], unique: true
  end

  def down
    remove_index :invites, column: [:email, :dossier_id]
  end
end
