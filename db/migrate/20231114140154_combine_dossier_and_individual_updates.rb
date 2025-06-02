# frozen_string_literal: true

class CombineDossierAndIndividualUpdates < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_column :dossiers, :mandataire_first_name, :string unless column_exists?(:dossiers, :mandataire_first_name)
      add_column :dossiers, :mandataire_last_name, :string unless column_exists?(:dossiers, :mandataire_last_name)
      add_column :dossiers, :for_tiers, :boolean, default: false, null: false

      add_column :individuals, :notification_method, :string
      add_column :individuals, :email, :string
      add_index :individuals, :email, algorithm: :concurrently
    end
  end
end
