# frozen_string_literal: true

class AddChampsRowIdIndex < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :champs, [:type_de_champ_id, :dossier_id, :row_id], unique: true, algorithm: :concurrently
  end
end
