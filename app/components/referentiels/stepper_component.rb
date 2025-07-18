# frozen_string_literal: true

class Referentiels::StepperComponent < ViewComponent::Base
  attr_reader :referentiel, :type_de_champ, :procedure, :step_component

  def initialize(referentiel:, type_de_champ:, procedure:, step_component:)
    @referentiel = referentiel
    @type_de_champ = type_de_champ
    @procedure = procedure
    @step_component = step_component
  end

  def step_state
    "Étape #{current_step} sur #{step_count}"
  end

  def step_title
    if step_component == Referentiels::NewFormComponent
      "Requête"
    elsif step_component == Referentiels::MappingFormComponent
      "Réponse et mapping"
    elsif step_component == Referentiels::PrefillAndDisplayComponent
      "Pré remplissage des champs et/ou affichage des données récupérées"
    end
  end

  def next_step_title
    if step_component == Referentiels::NewFormComponent
      "Configuration de l'autocomplétion"
    elsif step_component == Referentiels::NewFormComponent
      "Réponse et mapping"
    elsif step_component == Referentiels::MappingFormComponent
      "Pré remplissage des champs et/ou affichage des données récupérées"
    end
  end

  def current_step
    return 1 if step_component == Referentiels::NewFormComponent

    case [step_component, referentiel.mode]
    when [Referentiels::MappingFormComponent, 'exact_match']
      2
    when [Referentiels::PrefillAndDisplayComponent, 'exact_match']
      3
    end
  end

  def step_count
    3
  end
end
