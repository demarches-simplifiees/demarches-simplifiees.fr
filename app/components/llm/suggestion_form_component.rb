# frozen_string_literal: true

class LLM::SuggestionFormComponent < ApplicationComponent
  RULES = {
    LLM::LabelImprover::TOOL_NAME => {
      title: 'Améliorer les libellés des champs',
      summary: <<~DESCRIPTION.squish,
        Cette règle propose une mise à jour des libellés détectés comme trop longs, en majuscules ou difficiles à comprendre.
        Les suggestions visent à rendre chaque champ plus clair pour l’usager sans impacter la structure de la démarche.
      DESCRIPTION
      item_component: LLM::ImproveLabelItemComponent,
      select_all: false
    },
    LLM::StructureImprover::TOOL_NAME => {
      title: 'Amélioration de la structure',
      summary: <<~DESCRIPTION.squish,
        Propose l’ajout de sections et le repositionnement des champs pour rendre la démarche plus lisible sans supprimer de contenu.
      DESCRIPTION
      item_component: LLM::ImproveStructureItemComponent,
      select_all: true
    }
  }.freeze

  attr_reader :llm_rule_suggestion

  def initialize(llm_rule_suggestion:)
    @llm_rule_suggestion = llm_rule_suggestion
    @config = self.class.configuration_for(llm_rule_suggestion.rule)
  end

  def self.configuration_for(rule)
    RULES.fetch(rule) { raise "Unknown rule #{rule}" }
  end

  def title = @config[:title]
  def summary = @config[:summary]
  def item_component = @config[:item_component]
  def select_all? = @config[:select_all]

  def form_data
    select_all? ? { controller: 'checkbox-select-all' } : {}
  end

  def procedure_revision
    llm_rule_suggestion.procedure_revision
  end

  def procedure
    procedure_revision.procedure
  end

  def back_link
    helpers.simplify_index_admin_procedure_types_de_champ_path(procedure)
  end

  def render?
    llm_rule_suggestion.present?
  end
end
