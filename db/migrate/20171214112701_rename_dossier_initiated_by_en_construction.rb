class RenameDossierInitiatedByEnConstruction < ActiveRecord::Migration[5.0]
  def change
    rename_column :dossiers, :initiated_at, :en_construction_at
  end
end
