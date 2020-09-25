FactoryBot.define do
  factory :invite do
    email { 'plop@octo.com' }
    user { nil }
    association :dossier

    after(:build) do |invite, _evaluator|
      if invite.user.present?
        invite.email = invite.user.email
      end
    end

    trait :with_user do
      association :user
    end
  end
end
