SELECT dossiers.id AS dossier_id,
  dossiers.id::text AS term
  FROM dossiers

UNION SELECT cerfas.dossier_id,
  cerfas.content AS term
  FROM cerfas

UNION SELECT champs.dossier_id,
  champs.value || ' ' ||
  drop_down_lists.value AS term
  FROM champs
  INNER JOIN drop_down_lists ON drop_down_lists.type_de_champ_id = champs.type_de_champ_id

UNION SELECT entreprises.dossier_id,
  entreprises.siren || ' ' ||
  entreprises.numero_tva_intracommunautaire || ' ' ||
  entreprises.forme_juridique || ' ' ||
  entreprises.forme_juridique_code || ' ' ||
  entreprises.nom_commercial || ' ' ||
  entreprises.raison_sociale || ' ' ||
  entreprises.siret_siege_social || ' ' ||
  entreprises.nom || ' ' ||
  entreprises.prenom || ' ' ||
  rna_informations.association_id || ' ' ||
  rna_informations.titre || ' ' ||
  rna_informations.objet AS term
  FROM entreprises
  INNER JOIN rna_informations ON rna_informations.entreprise_id = entreprises.id

UNION SELECT etablissements.dossier_id,
  etablissements.siret || ' ' ||
  etablissements.naf || ' ' ||
  etablissements.libelle_naf || ' ' ||
  etablissements.adresse || ' ' ||
  etablissements.code_postal || ' ' ||
  etablissements.localite || ' ' ||
  etablissements.code_insee_localite AS term
  FROM etablissements

UNION SELECT individuals.dossier_id,
  individuals.nom || ' ' ||
  individuals.prenom AS term
  FROM individuals

UNION SELECT pieces_justificatives.dossier_id,
  pieces_justificatives.content AS term
  FROM pieces_justificatives

UNION SELECT dossiers.id,
  france_connect_informations.given_name || ' ' ||
  france_connect_informations.family_name AS term
  FROM france_connect_informations
  INNER JOIN dossiers ON dossiers.user_id = france_connect_informations.user_id
