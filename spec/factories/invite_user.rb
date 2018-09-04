FactoryBot.define do
  factory :invite_user do
    email { 'plop@octo.com' }

    after(:build) do |invite, _evaluator|
      if invite.dossier.nil?
        invite.dossier = create(:dossier)
      end

      if invite.user.present?
        invite.email = invite.user.email
      end
    end

    trait :with_user do
      after(:build) do |invite, _evaluator|
        if invite.user.nil?
          invite.user = create(:user)
          invite.email = invite.user.email
        end
      end
    end
  end
end
