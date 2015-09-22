class ChangeAttributsToDossier < ActiveRecord::Migration
  def change
    remove_column :dossiers, :lien_plus_infos
    remove_column :dossiers, :mail_contact

    rename_column :dossiers, :ref_dossier, :ref_dossier_carto
  end
end
