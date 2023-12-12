FactoryBot.define do
  sequence(:instructeur_email) { |n| "inst#{n}@inst.com" }

  factory :instructeur do
    bypass_email_login_token { true }

    user { association :user, email: email, password: password }

    transient do
      email { generate(:instructeur_email) }
      password { 'somethingverycomplated!' }
    end

    trait :with_agent_connect_information do
      after(:create) do |instructeur, _evaluator|
        create(:agent_connect_information, instructeur: instructeur)
      end
    end
  end
end
