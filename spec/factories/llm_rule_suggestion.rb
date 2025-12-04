# frozen_string_literal: true

FactoryBot.define do
  factory :llm_rule_suggestion, class: LLMRuleSuggestion do
    procedure_revision
    schema_hash { 'test_hash' }
    rule { 'improve_label' }

    trait :queued do
      state { 'queued' }
      rule { LLMRuleSuggestion.rules.fetch('improve_label') }
    end
  end
end
