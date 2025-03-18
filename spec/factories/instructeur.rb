# frozen_string_literal: true

FactoryBot.define do
  sequence(:instructeur_email) { |n| "inst#{n}@inst.com" }

  factory :instructeur do
    bypass_email_login_token { true }

    user { association :user, email: email, password: password }

    transient do
      email { generate(:instructeur_email) }
      password { '{My-$3cure-p4ssWord}' }
    end

    trait :email_verified do
      after(:create) do |instructeur|
        instructeur.user.update(email_verified_at: Time.zone.now)
      end
    end

    trait :with_pro_connect_information do
      after(:create) do |instructeur, _evaluator|
        create(:pro_connect_information, instructeur: instructeur)
      end
    end
  end
end
