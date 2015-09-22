FactoryGirl.define do
  sequence(:gestionnaire_email) { |n| "plop#{n}@plop.com" }
  factory :gestionnaire do
    email { generate(:gestionnaire_email) }
    password 'password'
  end
end