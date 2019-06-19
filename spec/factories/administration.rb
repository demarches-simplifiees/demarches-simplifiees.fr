FactoryBot.define do
  sequence(:administration_email) { |n| "plop#{n}@plop.com" }
  factory :administration do
    email { generate(:administration_email) }
    password { 'démarches-simplifiées-pwd' }
  end
end
