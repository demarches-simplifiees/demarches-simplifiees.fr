class AddEntrepriseToEtablissement < ActiveRecord::Migration[5.2]
  def change
    add_column :etablissements, :entreprise_siren, :string
    add_column :etablissements, :entreprise_capital_social, :integer
    add_column :etablissements, :entreprise_numero_tva_intracommunautaire, :string
    add_column :etablissements, :entreprise_forme_juridique, :string
    add_column :etablissements, :entreprise_forme_juridique_code, :string
    add_column :etablissements, :entreprise_nom_commercial, :string
    add_column :etablissements, :entreprise_raison_sociale, :string
    add_column :etablissements, :entreprise_siret_siege_social, :string
    add_column :etablissements, :entreprise_code_effectif_entreprise, :string
    add_column :etablissements, :entreprise_date_creation, :date
    add_column :etablissements, :entreprise_nom, :string
    add_column :etablissements, :entreprise_prenom, :string

    add_column :etablissements, :association_rna, :string
    add_column :etablissements, :association_titre, :string
    add_column :etablissements, :association_objet, :text
    add_column :etablissements, :association_date_creation, :date
    add_column :etablissements, :association_date_declaration, :date
    add_column :etablissements, :association_date_publication, :date

    add_column :champs, :etablissement_id, :integer, index: true
    add_column :exercices, :date_fin_exercice, :datetime
  end
end
