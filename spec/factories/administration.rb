FactoryGirl.define do
  sequence(:administration_email) { |n| "plop#{n}@plop.com" }
  factory :administration do
    email { generate(:administration_email) }
    password 'password'
  end
end