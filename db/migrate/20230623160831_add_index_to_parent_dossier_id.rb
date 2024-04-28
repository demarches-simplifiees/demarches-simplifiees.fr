# frozen_string_literal: true

class AddIndexToParentDossierId < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :dossiers, :parent_dossier_id, algorithm: :concurrently
  end
end
