class CreateRefPiecesJointes < ActiveRecord::Migration
  def change
    create_table :ref_pieces_jointes do |t|
      t.string :CERFA
      t.string :nature
      t.string :libelle_complet
      t.string :etablissement
      t.string :libelle
      t.string :description
      t.string :demarche
      t.string :administration_emetrice
      t.boolean :api_entreprise

      t.timestamps null: false
    end
  end
end
