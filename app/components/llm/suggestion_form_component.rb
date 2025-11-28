# frozen_string_literal: true

class LLM::SuggestionFormComponent < ApplicationComponent
  attr_reader :llm_rule_suggestion

  delegate :rule, :procedure_revision, to: :llm_rule_suggestion
  delegate :procedure, to: :procedure_revision
  delegate :step_title, :step_summary, to: :item_component

  def initialize(llm_rule_suggestion:)
    @llm_rule_suggestion = llm_rule_suggestion
  end

  def step_rule
    rule
  end

  def ordered_llm_rule_suggestion_items
    llm_rule_suggestion
      .llm_rule_suggestion_items
      .sort_by { it.payload["position"] }
  end

  def item_component
    case rule
    when 'improve_label'
      LLM::ImproveLabelItemComponent
    when 'improve_structure'
      LLM::ImproveStructureItemComponent
    else
      raise "Unknown LLM rule suggestion view component for rule: #{rule}"
    end
  end

  def prtdcs
    procedure_revision.types_de_champ_public.index_by(&:stable_id)
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

  def button_options
    {
      class: class_names(
        'fr-btn' => true,
        'fr-btn--tertiary' => llm_rule_suggestion.state.in?(['running', 'queued']),
        'fr-btn--spin' => llm_rule_suggestion.state.in?(['running', 'queued']),
        'fr-icon-search-line fr-btn--icon-left' => llm_rule_suggestion.state.in?(['pending', 'failed', 'accepted', 'skipped'])
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
      tag.p(class: 'fr-mb-0') { t('.not_completed.message1') },
      tag.p(class: 'fr-text--bold') { t('.not_completed.message2') },
      llm_rule_suggestion.state.in?(['failed', 'accepted', 'skipped']) ? tag.p(class: '') { t(".states.#{llm_rule_suggestion.state}") } : nil,
    ])
  end

  def display_button?
    !llm_rule_suggestion.persisted? || show_button?
  end

  private

  def render?
    llm_rule_suggestion.present?
  end
end
