FactoryGirl.define do
  factory :exercice do
    ca '12345678'
    dateFinExercice "2014-12-30 23:00:00"
    date_fin_exercice_timestamp 1419980400
    association :etablissement, factory: [:etablissement]
  end
end
