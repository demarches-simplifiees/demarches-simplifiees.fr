# frozen_string_literal: true

class LLMRuleSuggestion < ApplicationRecord
  belongs_to :procedure_revision

  has_many :llm_rule_suggestion_items, dependent: :destroy

  enum :state, { queued: 'queued', running: 'running', completed: 'completed', failed: 'failed' }

  validates :schema_hash, presence: true
  validates :rule, presence: true

  accepts_nested_attributes_for :llm_rule_suggestion_items

  def llm_rule_suggestion_items_attributes=(attributes)
    attributes.each do |(_idx, llm_rule_suggestion_items_attribute)|
      llm_rule_suggestion_item = llm_rule_suggestion_items.find { it.id.to_i == llm_rule_suggestion_items_attribute[:id].to_i }
      next unless llm_rule_suggestion_item

      if llm_rule_suggestion_items_attribute[:verify_status] == 'accepted'
        llm_rule_suggestion_item.verify_status = 'accepted'
        llm_rule_suggestion_item.applied_at = Time.current
      else
        llm_rule_suggestion_item.verify_status = 'skipped'
        llm_rule_suggestion_item.applied_at = nil
      end
    end
  end

  def changes_to_apply
    llm_rule_suggestion_items.accepted.group_by(&:op_kind).transform_keys(&:to_sym)
  end
end
