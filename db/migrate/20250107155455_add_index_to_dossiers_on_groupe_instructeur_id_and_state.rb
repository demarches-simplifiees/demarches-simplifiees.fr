# frozen_string_literal: true

class AddIndexToDossiersOnGroupeInstructeurIdAndState < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :dossiers, [:groupe_instructeur_id, :state, :archived], where: "hidden_by_administration_at IS NULL AND hidden_by_expired_at IS NULL", algorithm: :concurrently
  end
end
