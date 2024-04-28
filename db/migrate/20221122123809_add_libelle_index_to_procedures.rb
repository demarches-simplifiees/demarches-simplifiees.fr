# frozen_string_literal: true

class AddLibelleIndexToProcedures < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :procedures, :libelle, algorithm: :concurrently
  end
end
