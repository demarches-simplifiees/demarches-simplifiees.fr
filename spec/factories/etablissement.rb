FactoryGirl.define do
  factory :etablissement do
    siret '44011762001530'
    siege_social true
    naf '4950Z'
    libelle_naf 'Transports par conduites'
    adresse "GRTGAZ\r IMMEUBLE BORA\r 6 RUE RAOUL NORDLING\r 92270 BOIS COLOMBES\r"
    numero_voie '6'
    type_voie 'RUE'
    nom_voie 'RAOUL NORDLING'
    complement_adresse 'IMMEUBLE BORA'
    code_postal '92270'
    localite 'BOIS COLOMBES'
    code_insee_localite '92009'
  end
end
