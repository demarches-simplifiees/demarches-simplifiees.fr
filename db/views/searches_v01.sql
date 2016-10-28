SELECT dossiers.id AS dossier_id,
  dossiers.id::text || ' ' ||
  COALESCE(users.email, '') AS term
  FROM dossiers
  INNER JOIN users ON users.id = dossiers.user_id

UNION SELECT cerfas.dossier_id,
  COALESCE(cerfas.content, '') AS term
  FROM cerfas

UNION SELECT champs.dossier_id,
  COALESCE(champs.value, '') || ' ' ||
  COALESCE(drop_down_lists.value, '') AS term
  FROM champs
  INNER JOIN drop_down_lists ON drop_down_lists.type_de_champ_id = champs.type_de_champ_id

UNION SELECT entreprises.dossier_id,
  COALESCE(entreprises.siren, '') || ' ' ||
  COALESCE(entreprises.numero_tva_intracommunautaire, '') || ' ' ||
  COALESCE(entreprises.forme_juridique, '') || ' ' ||
  COALESCE(entreprises.forme_juridique_code, '') || ' ' ||
  COALESCE(entreprises.nom_commercial, '') || ' ' ||
  COALESCE(entreprises.raison_sociale, '') || ' ' ||
  COALESCE(entreprises.siret_siege_social, '') || ' ' ||
  COALESCE(entreprises.nom, '') || ' ' ||
  COALESCE(entreprises.prenom, '') || ' ' ||
  COALESCE(rna_informations.association_id, '') || ' ' ||
  COALESCE(rna_informations.titre, '') || ' ' ||
  COALESCE(rna_informations.objet, '') AS term
  FROM entreprises
  LEFT JOIN rna_informations ON rna_informations.entreprise_id = entreprises.id

UNION SELECT etablissements.dossier_id,
  COALESCE(etablissements.siret, '') || ' ' ||
  COALESCE(etablissements.naf, '') || ' ' ||
  COALESCE(etablissements.libelle_naf, '') || ' ' ||
  COALESCE(etablissements.adresse, '') || ' ' ||
  COALESCE(etablissements.code_postal, '') || ' ' ||
  COALESCE(etablissements.localite, '') || ' ' ||
  COALESCE(etablissements.code_insee_localite, '') AS term
  FROM etablissements

UNION SELECT individuals.dossier_id,
  COALESCE(individuals.nom, '') || ' ' ||
  COALESCE(individuals.prenom, '') AS term
  FROM individuals

UNION SELECT pieces_justificatives.dossier_id,
  COALESCE(pieces_justificatives.content, '') AS term
  FROM pieces_justificatives

UNION SELECT dossiers.id,
  COALESCE(france_connect_informations.given_name, '') || ' ' ||
  COALESCE(france_connect_informations.family_name, '') AS term
  FROM france_connect_informations
  INNER JOIN dossiers ON dossiers.user_id = france_connect_informations.user_id
