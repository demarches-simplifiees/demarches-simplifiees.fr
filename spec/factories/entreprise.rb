FactoryGirl.define do
  factory :entreprise do
    siren '440117620'
    capital_social 537_100_000
    numero_tva_intracommunautaire 'FR27440117620'
    forme_juridique 'SA à conseil d\'administration (s.a.i.)'
    forme_juridique_code '5599'
    nom_commercial 'GRTGAZ'
    raison_sociale 'GRTGAZ'
    siret_siege_social '44011762001530'
    code_effectif_entreprise '51'
    date_creation Time.at(1453976189).to_datetime
  end
end
