# frozen_string_literal: true

class AddChampsEtablissementIdIndex < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :champs, :etablissement_id, algorithm: :concurrently
  end
end
