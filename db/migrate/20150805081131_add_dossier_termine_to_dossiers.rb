class AddDossierTermineToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :dossier_termine, :boolean
  end
end
