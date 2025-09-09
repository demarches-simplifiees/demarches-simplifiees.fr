# frozen_string_literal: true

class LLMRuleSuggestionItem < ApplicationRecord
  belongs_to :llm_rule_suggestion

  enum :safety, { safe: 'safe', review: 'review' }
  enum :verify_status, { pending: 'pending', ok: 'ok', still_proposed: 'still_proposed', skipped: 'skipped' }

  validates :op_kind, presence: true
  validates :op_kind, inclusion: { in: %w[update add destroy] }
end
