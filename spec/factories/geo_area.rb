FactoryBot.define do
  factory :geo_area do
    source { GeoArea.sources.fetch(:cadastre) }
    numero { '42' }
    feuille { 'A11' }

    trait :quartier_prioritaire do
      source { GeoArea.sources.fetch(:quartier_prioritaire) }
      nom { 'XYZ' }
      commune { 'Paris' }
    end

    trait :selection_utilisateur do
      source { GeoArea.sources.fetch(:selection_utilisateur) }
    end
  end
end
