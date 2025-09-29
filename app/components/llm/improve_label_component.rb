# frozen_string_literal: true

class LLM::ImproveLabelComponent < LLM::RuleComponent
  def self.libelle = 'Améliorer les libellés des champs'
  def self.key = LLM::LabelImprover::TOOL_NAME

  def self.summary
    <<-DESCRIPTION
      Cette règle propose une mise à jour des libellés détectés comme trop longs, en majuscules ou difficiles à comprendre.
      Les suggestions visent à rendre chaque champ plus clair pour l’usager sans impacter la structure de la démarche.
    DESCRIPTION
  end

  private
end
