FactoryBot.define do
  factory :llm_rule_suggestion, class: LLMRuleSuggestion do
    trait :queued do
      state { 'queued' }
      rule { LLM::LabelImprover::TOOL_NAME }
    end
  end
end
