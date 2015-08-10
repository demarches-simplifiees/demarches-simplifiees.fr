class AddDossierTermineToDossiers < ActiveRecord::Migration
  def change
    add_column :dossiers, :dossier_termine, :boolean
  end
end
