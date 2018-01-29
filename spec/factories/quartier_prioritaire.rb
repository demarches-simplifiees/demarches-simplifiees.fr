FactoryBot.define do
  factory :quartier_prioritaire do
    code 'QPcode'
    commune 'Paris'
    nom 'Test des QP'
    geometry '{"type": "MultiPolygon", "coordinates": [[[[2.37112834276229, 48.8773116214902], [2.37163254350824, 48.8775780792784],  [2.37112834276229, 48.8773116214902]]]]}'
  end
end
