FactoryBot.define do
  sequence(:gestionnaire_email) { |n| "gest#{n}@gest.com" }
  factory :gestionnaire do
    email { generate(:gestionnaire_email) }
    password { 'password' }
  end

  trait :with_trusted_device do
    after(:create) do |gestionnaire|
      gestionnaire.update(features: { "enable_email_login_token" => true })
    end
  end
end
