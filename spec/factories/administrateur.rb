FactoryBot.define do
  sequence(:administrateur_email) { |n| "admin#{n}@admin.com" }
  factory :administrateur do
    email { generate(:administrateur_email) }

    transient do
      password { 'mon chien aime les bananes' }
    end

    initialize_with do
      User.create_or_promote_to_administrateur(email, password).administrateur
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
