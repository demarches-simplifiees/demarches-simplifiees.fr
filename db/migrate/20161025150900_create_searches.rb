class CreateSearches < ActiveRecord::Migration
  def up
    create_view :searches, materialized: true

    matrix.each do |table, fields|
      fields.each do |field|
        execute "CREATE INDEX tsv_index_#{table}_on_#{field} ON #{table} USING GIN(to_tsvector('french', #{field}))"
      end
    end
  end

  def down
    drop_view :searches

    matrix.each do |table, fields|
      fields.each do |field|
        execute "DROP INDEX IF EXISTS tsv_index_#{table}_on_#{field}"
      end
    end
  end

  def matrix
    {
      cerfas: %i(
        content
      ),
      champs: %i(
        value
      ),
      entreprises: %i(
        siren
        numero_tva_intracommunautaire
        forme_juridique
        forme_juridique_code
        nom_commercial
        raison_sociale
        siret_siege_social
        nom
        prenom
      ),
      rna_informations: %i(
        association_id
        titre
        objet
      ),
      etablissements: %i(
        siret
        naf
        libelle_naf
        adresse
        code_postal
        localite
        code_insee_localite
      ),
      individuals: %i(
        nom
        prenom
      ),
      pieces_justificatives: %i(
        content
      ),
      france_connect_informations: %i(
        given_name
        family_name
      ),
    }
  end
end
