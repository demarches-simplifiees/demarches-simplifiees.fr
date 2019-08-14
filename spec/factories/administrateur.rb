FactoryBot.define do
  sequence(:administrateur_email) { |n| "admin#{n}@admin.com" }
  factory :administrateur do
    email { generate(:administrateur_email) }

    transient do
      user { nil }
      password { 'mon chien aime les bananes' }
    end

    after(:create) do |administrateur, evaluator|
      if evaluator.user.present?
        user = evaluator.user
      else
        user = create(:user, email: administrateur.email, password: evaluator.password, administrateur: administrateur)
      end

      create(:instructeur, email: administrateur.email, user: user)
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
