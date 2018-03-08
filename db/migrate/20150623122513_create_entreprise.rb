class CreateEntreprise < ActiveRecord::Migration[5.2]
  def change
    create_table :entreprises do |t|
      t.string :siren
      t.integer :capital_social
      t.string :numero_tva_intracommunautaire
      t.string :forme_juridique
      t.string :forme_juridique_code
      t.string :nom_commercial
      t.string :raison_sociale
      t.string :siret_siege_social
      t.string :code_effectif_entreprise
      t.integer :date_creation
      t.string :nom
      t.string :prenom
    end
    add_reference :entreprises, :dossier, references: :dossiers
  end
end
