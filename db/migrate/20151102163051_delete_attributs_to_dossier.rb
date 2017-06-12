class DeleteAttributsToDossier < ActiveRecord::Migration
  def change
    remove_column :dossiers, :montant_projet
    remove_column :dossiers, :montant_aide_demande
    remove_column :dossiers, :date_previsionnelle
    remove_column :dossiers, :position_lat

    remove_column :dossiers, :position_lon
    remove_column :dossiers, :ref_dossier_carto
  end
end
