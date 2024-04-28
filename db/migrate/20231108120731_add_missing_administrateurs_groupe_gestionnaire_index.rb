# frozen_string_literal: true

class AddMissingAdministrateursGroupeGestionnaireIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    if !index_exists?(:administrateurs, :groupe_gestionnaire_id) # index may have already been added on other environments by a previous migration
      add_index :administrateurs, :groupe_gestionnaire_id, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:administrateurs, :groupe_gestionnaire_id)
      remove_index :administrateurs, :groupe_gestionnaire_id
    end
  end
end
