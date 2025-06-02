# frozen_string_literal: true

class AddGroupeGestionnaireToAdministrateurs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # Foreign key is added in a later migration
    add_reference :administrateurs, :groupe_gestionnaire, index: { algorithm: :concurrently }, null: true, foreign_key: false
  end
end
