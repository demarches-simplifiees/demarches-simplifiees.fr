FactoryBot.define do
  sequence(:user_email) { |n| "user#{n}@user.com" }
  factory :user do
    email { generate(:user_email) }
    password { TEST_PASSWORD }
    confirmed_at { Time.zone.now }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :with_strong_password do
      password { '{my-%s3cure[]-p4$$w0rd' }
    end
  end
end
