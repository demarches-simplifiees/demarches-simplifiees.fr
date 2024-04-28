# frozen_string_literal: true

FactoryBot.define do
  sequence(:administrateur_email) { |n| "admin#{n}@admin.com" }
  factory :administrateur do
    user { association :user, email: email, password: password }

    transient do
      email { generate(:administrateur_email) }
      password { 'Mon [hien 4im3 {es banane$' }
      instructeur { build(:instructeur, user: user) }
    end

    after(:build) do |administrateur, evaluator|
      if administrateur.user
        administrateur.user.instructeur = evaluator.instructeur
      end
    end
  end

  trait :with_api_token do
    after(:create) do |admin|
      APIToken.generate(admin)
    end
  end

  trait :with_procedure do
    after(:create) do |admin|
      create(:simple_procedure, administrateur: admin)
      admin.reload
    end
  end
end
