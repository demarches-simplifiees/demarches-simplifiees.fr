class RenameTableFormulaireToProcedure < ActiveRecord::Migration[5.2]
  def change
    remove_column :formulaires, :demarche_id
    remove_column :formulaires, :cigle_ministere
    remove_column :formulaires, :evenement_vie_id
    remove_column :formulaires, :publics
    remove_column :formulaires, :lien_fiche_signaletique
    remove_column :formulaires, :lien_notice
    remove_column :formulaires, :categorie
    remove_column :formulaires, :mail_pj
    remove_column :formulaires, :email_contact

    rename_column :formulaires, :nom, :libelle
    rename_column :formulaires, :objet, :description
    rename_column :formulaires, :ministere, :organisation
    rename_column :formulaires, :use_admi_facile, :test

    rename_table :formulaires, :procedures
  end
end
