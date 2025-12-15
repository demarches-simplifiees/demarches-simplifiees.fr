# frozen_string_literal: true

class LLMRuleSuggestion < ApplicationRecord
  belongs_to :procedure_revision

  has_many :llm_rule_suggestion_items, dependent: :destroy

  enum :state, { pending: 'pending', queued: 'queued', running: 'running', completed: 'completed', failed: 'failed', accepted: 'accepted', skipped: 'skipped' }
  enum :rule, { improve_label: 'improve_label', improve_structure: 'improve_structure', consolidate_types: 'consolidate_types' }

  RULE_SEQUENCE = %w[improve_label improve_structure consolidate_types].freeze

  RULE_CONFIG = {
    'improve_label' => {
      item_component_class: 'LLM::ImproveLabelItemComponent',
      service_class: 'LLM::LabelImprover',
    },
    'improve_structure' => {
      item_component_class: 'LLM::ImproveStructureItemComponent',
      service_class: 'LLM::StructureImprover',
    },
    'consolidate_types' => {
      item_component_class: 'LLM::ConsolidateTypesItemComponent',
      service_class: 'LLM::TypesConsolidator',
    },
  }.freeze

  scope :last_for_procedure_revision, -> {
    order(created_at: :desc).first
  }

  validates :schema_hash, presence: true
  validates :rule, presence: true

  accepts_nested_attributes_for :llm_rule_suggestion_items

  class << self
    def next_rule(current_rule)
      current_index = RULE_SEQUENCE.index(current_rule)
      return if current_index == RULE_SEQUENCE.length - 1

      RULE_SEQUENCE[current_index + 1]
    end

    def last_rule?(rule)
      next_rule(rule).nil?
    end

    def position_for(rule)
      RULE_SEQUENCE.index(rule)&.next
    end

    def item_component_class_for(rule)
      RULE_CONFIG.dig(rule, :item_component_class).constantize
    end

    def service_class_for(rule)
      RULE_CONFIG.dig(rule, :service_class).constantize
    end
  end

  def finished?
    accepted? || skipped?
  end

  def llm_rule_suggestion_items_attributes=(attributes)
    attributes.each do |(_idx, llm_rule_suggestion_items_attribute)|
      llm_rule_suggestion_item = llm_rule_suggestion_items.find { it.id == llm_rule_suggestion_items_attribute[:id].to_i }
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
