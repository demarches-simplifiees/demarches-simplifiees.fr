# frozen_string_literal: true

FactoryBot.define do
  factory :targeted_user_link do
    target_context { TargetedUserLink.target_contexts[:avis] }
    target_model { create(:avis) }
    transient do
      user {}
    end
    after(:build) do |targeted_user_link|
      case targeted_user_link.target_context
      when 'avis'
        targeted_user_link.user = targeted_user_link.target_model.expert.user
      when 'invite'
        targeted_user_link.user = targeted_user_link.target_model&.user
      end
    end
  end
end
