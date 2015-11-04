FactoryGirl.define do
  sequence(:administrateur_email) { |n| "plop#{n}@plop.com" }
  factory :administrateur do
    email { generate(:administrateur_email) }
    password 'password'
  end
end