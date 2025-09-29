# frozen_string_literal: true

module LLM
  # Orchestrates improve_label generation using tool-calling.
  # - generate_for(revision): returns normalized items built from tool_calls
  class LabelImprover < BaseImprover
    TOOL_NAME = 'improve_label'
    TOOL_DEFINITION = {
      type: 'function',
      function: {
        name: TOOL_NAME,
        description: 'Format the label improvement as a standardized operation.',
        parameters: {
          type: 'object',
          properties: {
            update: {
              type: 'object',
              properties: {
                stable_id: { type: 'integer', description: 'Target field stable id' },
                libelle: { type: 'string', description: 'New label (<= 80 chars, plain language)' },
              },
              required: %w[stable_id libelle],
            },
            justification: { type: 'string', description: 'Short reason for change' },
            confidence: { type: 'number', description: '0..1 confidence score' },
          },
          required: %w[update],
        },
      },
    }.freeze

    def system_prompt
      'Tu es un assistant qui améliore les libellés des champs de formulaires administratifs français.'
    end

    def schema_prompt
      <<~TXT
        Voici le schéma des champs (publics) du formulaire en JSON. Chaque entrée contient un stable_id, un type, un libellé, et éventuellement une description.
        <schema>
        %<schema>s
        </schema>
      TXT
    end

    def rules_prompt
      <<~TXT
        Règles:
        - Propose uniquement si le libellé peut être nettement amélioré (clarté, concision, casse correcte, éviter les majuscules intégrales).
        - Ne pas proposer si le gain est minime (distance d’édition très faible).
        - Longueur maximale 80 caractères.
        - Utiliser l’outil #{TOOL_NAME} pour chaque champ à améliorer (un appel par champ).
      TXT
    end

    def build_item(args)
      update = args['update'].is_a?(Hash) ? args['update'] : {}
      stable_id = update['stable_id'] || args['stable_id']
      libelle = (update['libelle'] || args['libelle']).to_s.strip
      return if stable_id.nil? || libelle.blank?

      {
        op_kind: 'update',
        stable_id: stable_id,
        payload: { 'stable_id' => stable_id, 'libelle' => libelle },
        safety: 'safe',
        justification: args['justification'].to_s.presence,
        confidence: args['confidence'],
      }
    end
  end
end
