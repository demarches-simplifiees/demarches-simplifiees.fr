FactoryBot.define do
  factory :individual do
    gender { 'Mme.' }
    nom { 'julien' }
    prenom { 'anne-marie' }
    birthdate { Date.new(1991, 11, 01) }
  end
end
