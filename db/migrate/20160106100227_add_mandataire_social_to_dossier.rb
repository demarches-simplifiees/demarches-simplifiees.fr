class AddMandataireSocialToDossier < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :mandataire_social, :boolean, default: false
  end
end
