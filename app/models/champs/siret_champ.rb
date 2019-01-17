class Champs::SiretChamp < Champ
  ETABLISSEMENT_ATTRIBUTES = [
    :id,
    :_destroy,
    :signature,
    :siret,
    :siege_social,
    :naf,
    :libelle_naf,
    :adresse,
    :numero_voie,
    :type_voie,
    :nom_voie,
    :code_postal,
    :localite,
    :code_insee_localite,
    :entreprise_siren,
    :entreprise_capital_social,
    :entreprise_numero_tva_intracommunautaire,
    :entreprise_forme_juridique,
    :entreprise_forme_juridique_code,
    :entreprise_nom_commercial,
    :entreprise_raison_sociale,
    :entreprise_siret_siege_social,
    :entreprise_code_effectif_entreprise,
    :entreprise_date_creation,
    :entreprise_nom,
    :entreprise_prenom,
    :association_rna,
    :association_titre,
    :association_objet,
    :association_date_creation,
    :association_date_declaration,
    :association_date_publication,
    exercices_attributes: [
      [:id, :ca, :date_fin_exercice, :date_fin_exercice_timestamp]
    ]
  ]

  accepts_nested_attributes_for :etablissement, allow_destroy: true, update_only: true

  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end
end
