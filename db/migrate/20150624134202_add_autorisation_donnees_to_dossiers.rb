class AddAutorisationDonneesToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :autorisation_donnees, :boolean
  end
end
