FactoryBot.define do
  factory :geo_area do
    source { GeoArea.sources.fetch(:cadastre) }
    numero { '42' }
    feuille { 'A11' }
  end
end
