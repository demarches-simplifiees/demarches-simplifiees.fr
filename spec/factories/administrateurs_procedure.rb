FactoryBot.define do
  factory :administrateurs_procedure do
    association :administrateur
    association :procedure
  end
end
