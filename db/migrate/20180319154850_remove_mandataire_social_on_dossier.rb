class RemoveMandataireSocialOnDossier < ActiveRecord::Migration[5.2]
  def change
    remove_column :dossiers, :mandataire_social
  end
end
