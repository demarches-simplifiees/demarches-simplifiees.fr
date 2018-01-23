FactoryBot.define do
  sequence(:user_email) { |n| "user#{n}@user.com" }
  factory :user do
    email { generate(:user_email) }
    password 'password'
  end
end
