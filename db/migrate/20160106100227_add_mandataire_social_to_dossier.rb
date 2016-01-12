class AddMandataireSocialToDossier < ActiveRecord::Migration
  def change
    add_column :dossiers, :mandataire_social, :boolean, default: false
  end
end
