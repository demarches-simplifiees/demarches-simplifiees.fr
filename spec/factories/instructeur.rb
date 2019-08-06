FactoryBot.define do
  sequence(:instructeur_email) { |n| "gest#{n}@gest.com" }
  factory :instructeur do
    email { generate(:instructeur_email) }
    password { 'démarches-simplifiées-pwd' }
  end
end
