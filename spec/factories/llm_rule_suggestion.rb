FactoryBot.define do
  factory :llm_rule_suggestion, class: LLMRuleSuggestion do
    trait :queued do
      state { 'queued' }
      rule { let(:rule) { LLMRuleSuggestion.rules.fetch('improve_label') } }
    end
  end
end
