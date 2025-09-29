# frozen_string_literal: true

class LLM::ImproveStructureComponent < LLM::RuleComponent
  class << self
    def libelle = 'Amélioration de la structure'
    def key = LLM::StructureImprover::TOOL_NAME
    def summary
      <<~DESCRIPTION.squish
        Propose l’ajout de sections et le repositionnement des champs pour rendre la démarche plus lisible sans supprimer de contenu.
      DESCRIPTION
    end
  end
end
