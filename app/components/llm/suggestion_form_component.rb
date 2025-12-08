# frozen_string_literal: true

class LLM::SuggestionFormComponent < ApplicationComponent
  attr_reader :llm_rule_suggestion

  delegate :rule, :procedure_revision, :state, to: :llm_rule_suggestion
  delegate :procedure, to: :procedure_revision
  delegate :step_title, to: :item_component

  def initialize(llm_rule_suggestion:)
    @llm_rule_suggestion = llm_rule_suggestion
  end

  def step_summary
    t(".summary.#{rule}_html")
  end

  def ordered_llm_rule_suggestion_items
    root_tdcs, children_tdcs = llm_rule_suggestion
      .llm_rule_suggestion_items
      .partition { |item| item.payload['parent_id'].nil? }
    children_by_parent_id = children_tdcs.group_by { |item| item.payload['parent_id'] }

    root_tdcs
      .sort_by { |item| item.payload['position'] }
      .flat_map do |root_item|
        [root_item] +
          (children_by_parent_id[root_item.payload['stable_id']] || []).sort_by { |item| item.payload['position'] }
      end
  end

  def item_component
    LLMRuleSuggestion.item_component_class_for(rule)
  end

  def prtdcs
    procedure_revision.types_de_champ.index_by(&:stable_id)
  end

  def back_link
    helpers.admin_procedure_path(procedure)
  end

  def suggestions_count
    llm_rule_suggestion.llm_rule_suggestion_items.size
  end

  def enqueue_button_text
    t(".buttons.#{llm_rule_suggestion.state}")
  end

  def at_least_one_accepted?
    ordered_llm_rule_suggestion_items.any? { |item| item.verify_status == 'accepted' }
  end

  def button_options
    {
      class: class_names(
        'fr-btn' => true,
        'fr-btn--tertiary' => llm_rule_suggestion.state.in?(['running', 'queued']),
        'fr-btn--spin' => llm_rule_suggestion.state.in?(['running', 'queued']),
        'fr-icon-search-ai-line fr-btn--icon-left' => llm_rule_suggestion.state.in?(['pending', 'failed', 'accepted', 'skipped'])
      ),
    }
  end

  def button
    if llm_rule_suggestion.state.in?(['running', 'queued'])
      tag.span(**button_options) { enqueue_button_text }
    else
      button_to enqueue_button_text, enqueue_simplify_admin_procedure_types_de_champ_path(procedure, rule:), button_options
    end
  end

  def status_message
    t(".states.#{llm_rule_suggestion.state}")
  end

  def display_message
    safe_join([
      llm_rule_suggestion.state.in?(['pending', 'failed', 'accepted', 'skipped']) ? tag.p(class: '') { t(".states.#{llm_rule_suggestion.state}") } : nil,
    ])
  end

  def last_rule?
    LLMRuleSuggestion.last_rule?(llm_rule_suggestion.rule)
  end

  def stepper_finished?
    llm_rule_suggestion.finished? && last_rule?
  end

  def should_poll?
    llm_rule_suggestion.state.in?(['running', 'queued'])
  end

  def poll_controller_data
    should_poll? ? 'turbo-poll' : ''
  end

  def poll_url
    helpers.poll_simplify_admin_procedure_types_de_champ_path(procedure, rule: rule)
  end

  private

  def render?
    llm_rule_suggestion.present?
  end
end
