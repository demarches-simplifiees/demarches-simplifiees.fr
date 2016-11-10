-- this version merges all possible search terms together, complicating the
-- view, but enables searching for multiple terms from multiple tables at once.

SELECT dossiers.id AS dossier_id,
  COALESCE(users.email, '') || ' ' ||
  COALESCE(france_connect_informations.given_name, '') || ' ' ||
  COALESCE(france_connect_informations.family_name, '') || ' ' ||
  COALESCE(cerfas.content, '') || ' ' ||
  COALESCE(champs.value, '') || ' ' ||
  COALESCE(drop_down_lists.value, '') || ' ' ||
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
  COALESCE(rna_informations.objet, '') || ' ' ||
  COALESCE(etablissements.siret, '') || ' ' ||
  COALESCE(etablissements.naf, '') || ' ' ||
  COALESCE(etablissements.libelle_naf, '') || ' ' ||
  COALESCE(etablissements.adresse, '') || ' ' ||
  COALESCE(etablissements.code_postal, '') || ' ' ||
  COALESCE(etablissements.localite, '') || ' ' ||
  COALESCE(etablissements.code_insee_localite, '') || ' ' ||
  COALESCE(individuals.nom, '') || ' ' ||
  COALESCE(individuals.prenom, '') || ' ' ||
  COALESCE(pieces_justificatives.content, '') AS term
FROM dossiers
INNER JOIN users ON users.id = dossiers.user_id
LEFT JOIN france_connect_informations ON france_connect_informations.user_id = dossiers.user_id
LEFT JOIN cerfas ON cerfas.dossier_id = dossiers.id
LEFT JOIN champs ON champs.dossier_id = dossiers.id
LEFT JOIN drop_down_lists ON drop_down_lists.type_de_champ_id = champs.type_de_champ_id
LEFT JOIN entreprises ON entreprises.dossier_id = dossiers.id
LEFT JOIN rna_informations ON rna_informations.entreprise_id = entreprises.id
LEFT JOIN etablissements ON etablissements.dossier_id = dossiers.id
LEFT JOIN individuals ON individuals.dossier_id = dossiers.id
LEFT JOIN pieces_justificatives ON pieces_justificatives.dossier_id = dossiers.id
