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

  def changes_json
    { update: update_items.map { |item| serialized_update(item) } }.to_json
  end

  def update_items
    @update_items ||= Array(changes['update'])
  end

  private

  def serialized_update(item)
    payload = item.payload || {}

    {
      stable_id: item.stable_id,
      libelle: payload['libelle'],
      type_champ: payload['type_champ'],
      justification: item.justification,
      confidence: item.confidence
    }.compact
  end
end
