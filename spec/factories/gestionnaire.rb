FactoryGirl.define do
  sequence(:gestionnaire_email) { |n| "gest#{n}@plop.com" }
  factory :gestionnaire do
    email { generate(:gestionnaire_email) }
    password 'password'
  end
end
