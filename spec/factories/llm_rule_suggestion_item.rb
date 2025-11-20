# frozen_string_literal: true

FactoryBot.define do
  factory :llm_rule_suggestion_item do
    association :llm_rule_suggestion
    op_kind { 'update' }
    stable_id { 123 }
    payload { { 'stable_id' => stable_id, 'libelle' => 'Proposition' } }
    safety { 'safe' }
    verify_status { 'pending' }
    justification { 'clarity' }
    confidence { 0.8 }
  end
end
