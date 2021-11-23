FactoryBot.define do
  factory :individual do
    gender { 'M.' }
    nom { 'Julien' }
    prenom { 'Xavier' }
    birthdate { Date.new(1991, 11, 01) }
    association :dossier

    trait :empty do
      gender { nil }
      nom { nil }
      prenom { nil }
      birthdate { nil }
    end
  end
end
