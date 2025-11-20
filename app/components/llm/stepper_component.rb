# frozen_string_literal: true

module LLM
  class StepperComponent < StepperBaseComponent
    delegate :llm_rule_suggestion, to: :step_component
    delegate :procedure_revision, :rule, to: :llm_rule_suggestion
    delegate :procedure, to: :procedure_revision

    def initialize(step_component:)
      super(step_component:)
    end

    def back_link
      helpers.link_to(
        "Revenir à l'écran de gestion",
        helpers.admin_procedure_path(procedure),
        class: 'fr-link fr-icon-arrow-left-line fr-link--icon--left fr-icon--sm'
      )
    end

    def title
      "Amélioration de la qualité du formulaire « #{procedure.libelle} »"
    end

    def step_title
      case rule
      when 'improve_label'
        "Amélioration des libellés"
      end
    end

    def next_step_title
      case rule
      when 'improve_label'
        "À venir..."
      end
    end

    def current_step
      case rule
      when 'improve_label'
        1
      end
    end

    def step_count
      4
    end
  end
end
