FactoryBot.define do
  factory :targeted_user_link do
    target_context { TargetedUserLink.target_contexts[:avis] }
    target_model { create(:avis) }
    transient do
      user {}
    end
    after(:build) do |targeted_user_link|
      targeted_user_link.user = targeted_user_link.target_model.expert.user
    end
  end
end
