# frozen_string_literal: true

module LLM
  # Orchestrates improve_label generation using tool-calling.
  # - generate_for(revision): returns normalized items built from tool_calls
  class LabelImprover
    TOOL_NAME = 'improve_label'

    # OpenAI-compatible tool schema.
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

    def initialize(runner: nil, logger: Rails.logger)
      @runner = runner
      @logger = logger
    end

    def tool_name
      self.class::TOOL_NAME
    end

    # Returns an array of hashes suitable for LlmRuleSuggestionItem creation
    # [{ rule:, op_kind:, stable_id:, payload:, safety:, justification:, confidence: }]
    def generate_for(revision)
      messages = propose_messages(revision)

      calls = run_tools(messages: messages, tools: [TOOL_DEFINITION])

      aggregate_calls(calls)
    end

    private

    def run_tools(messages:, tools:)
      return [] unless @runner

      @runner.call(messages: messages, tools: tools) || []
    rescue => e
      @logger.warn("[LLM] improve_label tools failed: #{e.class}: #{e.message}")
      []
    end

    def propose_messages(revision)
      propose_messages_for_schema(revision.schema_to_llm)
    end

    def propose_messages_for_schema(schema)
      [
        { role: 'system', content: system_prompt },
        { role: 'user', content: format(schema_prompt, schema: JSON.dump(schema)) },
        { role: 'user', content: rules_prompt }
      ]
    end

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

    def aggregate_calls(calls)
      calls
        .filter { |c| c[:name] == TOOL_NAME }
        .map do |call|
          args = call[:arguments] || {}
          update = args['update'].is_a?(Hash) ? args['update'] : {}
          stable_id = update['stable_id'] || args['stable_id']
          libelle = (update['libelle'] || args['libelle']).to_s.strip
          next if stable_id.nil? || libelle.blank?

          {
            op_kind: 'update',
            stable_id: stable_id,
            payload: { 'stable_id' => stable_id, 'libelle' => libelle },
            safety: 'safe',
            justification: args['justification'].to_s.presence,
            confidence: args['confidence']
          }
        end
        .compact
    end
  end
end
