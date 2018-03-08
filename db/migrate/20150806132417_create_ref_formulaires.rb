class CreateRefFormulaires < ActiveRecord::Migration[5.2]
  def change
    create_table :ref_formulaires do |t|
      t.string :ref_demarche
      t.string :nom
      t.string :objet
      t.string :ministere
      t.string :cigle_ministere
      t.string :direction
      t.string :evenement_vie
      t.string :publics
      t.string :lien_demarche
      t.string :lien_fiche_signaletique
      t.string :lien_notice
      t.string :categorie
      t.boolean :mail_pj

      t.timestamps null: false
    end
  end
end
