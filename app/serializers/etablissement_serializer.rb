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

  def adresse
    object.adresse.chomp.gsub("\r\n", ' ')
  end
end