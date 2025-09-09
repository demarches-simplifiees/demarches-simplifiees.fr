FactoryBot.define do
  factory :llm_rule_suggestion, class: LLMRuleSuggestion do
    trait :queued do
      state { 'queued' }
    end
  end
end
