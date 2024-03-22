class CombineDossierAndIndividualUpdates < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_column :dossiers, :mandataire_first_name, :string
    add_column :dossiers, :mandataire_last_name, :string
    add_column :dossiers, :for_tiers, :boolean, default: false, null: false

    add_column :individuals, :notification_method, :string
    add_column :individuals, :email, :string
    add_index :individuals, :email, algorithm: :concurrently
  end
end
