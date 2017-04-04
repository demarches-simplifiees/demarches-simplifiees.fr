FactoryGirl.define do
  sequence(:user_email) { |n| "plop#{n}@plop.com" }
  factory :user do
    email { generate(:user_email) }
    password 'password'
  end
end
