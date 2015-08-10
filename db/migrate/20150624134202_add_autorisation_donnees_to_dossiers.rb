class AddAutorisationDonneesToDossiers < ActiveRecord::Migration
  def change
    add_column :dossiers, :autorisation_donnees, :boolean
  end
end
