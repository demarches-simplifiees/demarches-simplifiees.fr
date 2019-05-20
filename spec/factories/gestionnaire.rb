FactoryBot.define do
  sequence(:gestionnaire_email) { |n| "gest#{n}@gest.com" }
  factory :gestionnaire do
    email { generate(:gestionnaire_email) }
    password { 'démarches-simplifiées pwd' }
  end
end
