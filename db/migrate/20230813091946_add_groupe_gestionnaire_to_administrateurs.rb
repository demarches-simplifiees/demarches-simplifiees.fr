class AddGroupeGestionnaireToAdministrateurs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :administrateurs, :groupe_gestionnaire, index: { algorithm: :concurrently }, null: true
  end
end
