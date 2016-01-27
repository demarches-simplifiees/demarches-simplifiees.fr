class EtablissementSerializer < ActiveModel::Serializer
  attributes :siret,
             :siege_social,
             :naf,
             :libelle_naf,
             :adresse,
             :numero_voie,
             :type_voie,
             :nom_voie,
             :complement_adresse,
             :code_postal,
             :localite,
             :code_insee_localite
end