# frozen_string_literal: true

FactoryBot.define do
  sequence(:user_email) { |n| "user#{n}@user.com" }
  factory :user do
    email { generate(:user_email) }
    password { SECURE_PASSWORD }
    confirmed_at { Time.zone.now }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :with_strong_password do
      password { '{my-%s3cure[]-p4$$w0rd' }
    end

    trait :with_fci do
      france_connect_informations { [association(:france_connect_information)] }
    end

    trait :with_email_verified do
      email_verified_at { Time.zone.now }
    end
  end
end
