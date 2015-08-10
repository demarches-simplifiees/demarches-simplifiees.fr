class CreateEtablissements < ActiveRecord::Migration
  def change
    create_table :etablissements do |t|
      t.string :siret
      t.boolean :siege_social
      t.string :naf
      t.string :libelle_naf
      t.string :adresse
      t.string :numero_voie
      t.string :type_voie
      t.string :nom_voie
      t.string :complement_adresse
      t.string :code_postal
      t.string :localite
      t.string :code_insee_localite
    end
    add_reference :etablissements, :dossier, references: :dossiers
    add_reference :etablissements, :entreprise, references: :entreprises
  end
end
