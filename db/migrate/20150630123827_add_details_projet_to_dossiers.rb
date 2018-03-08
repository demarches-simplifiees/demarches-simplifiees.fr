class AddDetailsProjetToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :nom_projet, :string
    add_column :dossiers, :montant_projet, :string
    add_column :dossiers, :montant_aide_demande, :string
    add_column :dossiers, :date_previsionnelle, :string
    add_column :dossiers, :lien_plus_infos, :string
    add_column :dossiers, :mail_contact, :string
  end
end
