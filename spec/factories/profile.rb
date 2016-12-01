FactoryGirl.define do
  factory :profile do
    association :user, factory: [:user]
    gender "male"
    given_name "John"
    family_name "Doe"
  end
end
