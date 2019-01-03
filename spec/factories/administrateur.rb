FactoryBot.define do
  sequence(:administrateur_email) { |n| "admin#{n}@admin.com" }
  factory :administrateur do
    email { generate(:administrateur_email) }
    password { 'mon chien aime les bananes' }
  end

  trait :with_api_token do
    after(:create) do |admin|
      admin.renew_api_token
    end
  end

  trait :with_procedure do
    after(:create) do |admin|
      admin.procedures << create(:simple_procedure, administrateur: admin)
    end
  end
end
