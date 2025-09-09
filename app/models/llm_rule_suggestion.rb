# frozen_string_literal: true

class LLMRuleSuggestion < ApplicationRecord
  belongs_to :procedure_revision

  has_many :llm_rule_suggestion_items, dependent: :destroy

  enum :state, { queued: 'queued', running: 'running', completed: 'completed', failed: 'failed' }

  validates :schema_hash, presence: true
  validates :rule, presence: true
end
