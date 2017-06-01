FactoryGirl.define do
  sequence(:administrateur_email) { |n| "admin#{n}@admin.com" }
  factory :administrateur do
    email { generate(:administrateur_email) }
    password 'password'
  end
end
