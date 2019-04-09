FactoryBot.define do
  sequence(:administrateur_email) { |n| "admin#{n}@admin.com" }
  factory :administrateur do
    email { generate(:administrateur_email) }
    password { 'mon chien aime les bananes' }

    after(:create) do |admin|
      create(:gestionnaire, email: admin.email, password: admin.password)
    end
  end

  trait :with_api_token do
    after(:create) do |admin|
      admin.renew_api_token
    end
  end

  trait :with_procedure do
    after(:create) do |admin|
      create(:simple_procedure, administrateur: admin)
      admin.reload
    end
  end
end
