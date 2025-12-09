# frozen_string_literal: true

module LLM
  class BaseImprover
    # Characters that could potentially interfere with LLM prompts or cause security issues
    DANGEROUS_CHARS = /
      [<>{}\[\]]     # Markup characters that could be used for injections
      | [\x00-\x1F]  # Control characters (null, tab, line feed, etc.)
      | \x7F         # Delete character
    /x.freeze

    attr_reader :runner, :logger

    def initialize(runner: nil, logger: Rails.logger)
      @runner = runner
      @logger = logger
    end

    # Returns an array of hashes suitable for LlmRuleSuggestionItem creation
    # [{ rule:, op_kind:, stable_id:, payload:, justification: }]
    def generate_for(suggestion, action: nil, user_id: nil)
      messages = propose_messages(suggestion)

      tool_calls, token_usage = run_tools(messages: messages, tools: [self.class::TOOL_DEFINITION], procedure_id: suggestion.procedure_revision.procedure_id, rule: suggestion.rule, action:, user_id:)
      [aggregate_calls(tool_calls, suggestion), token_usage.with_indifferent_access]
    end

    private

    def run_tools(messages:, tools:, procedure_id: nil, rule: nil, action: nil, user_id: nil)
      return [] unless @runner

      @runner.call(messages: messages, tools: tools, procedure_id:, rule:, action:, user_id:) || []
    end

    def propose_messages(suggestion)
      revision = suggestion.procedure_revision
      propose_messages_for_schema(
        revision.schema_to_llm,
        revision.procedure_context_to_llm
      )
    end

    def propose_messages_for_schema(schema, procedure_context)
      safe_schema = sanitize_schema_for_prompt(schema)
      [
        { role: 'system', content: format(system_prompt, procedure_context) },
        { role: 'user', content: format(schema_prompt, schema: JSON.dump(safe_schema)) },
        { role: 'user', content: rules_prompt },
      ]
    end

    def aggregate_calls(tool_calls, suggestion)
      tool_calls
        .filter { |call| call[:name] == suggestion.rule }
        .map do |call|
          args = call[:arguments] || {}
          build_item(args)
        end
        .compact
    end

    private

    def schema_prompt
      <<~PROMPT
        Voici le schéma des champs (publics) du formulaire en JSON. Chaque entrée contient :
          - stable_id : l'identifiant du champ
          - type : le type de champ
          - libellé : le libellé du champ
          - mandatory : indique si le champ est obligatoire ou non
          - description : la description du champ (optionnel)
          - choices : les options disponibles pour les champs de type liste déroulante (drop_down_list ou multiple_drop_down_list)
          - position : la position du champ dans le formulaire
          - parent_id : l'identifiant stable du champ parent, ou null s’il n’y a pas de parent
          - et éventuellement une description.

          Les type de champ possibles sont :
          - header_section : pour structurer le formulaire en sections (aucune saisie attendue, uniquement un libelle).
          - repetition : pour des blocs répétables de champs enfants ; l’usager peut répéter le bloc autant de fois qu’il le souhaite.
          - explication : pour fournir du contexte ou des consignes (aucune saisie attendue).
          - civilite : pour choisir « Madame » ou « Monsieur » ; l’administration connaît déjà cette information.
          - email : pour les adresses électroniques ; l’administration connaît déjà l’email de l’usager.
          - phone : pour les numéros de téléphone.
          - address : pour les adresses postales (auto-complétées avec commune, codes postaux, département, etc.).
          - communes : pour sélectionner des communes françaises (auto-complétées avec code, code postal, département, etc.).
          - departments : pour sélectionner des départements français.
          - text : pour des champs texte courts.
          - textarea : pour des champs texte longs.
          - integer_number : pour des nombres entiers.
          - decimal_number : pour des nombres décimaux.
          - date : pour sélectionner une date.
          - piece_justificative : pour téléverser des pièces justificatives (inutile de l’enfermer dans une répétition : plusieurs fichiers sont déjà possibles).
          - titre_identite : pour téléverser un titre d’identité de manière sécurisée.
          - checkbox : pour une case à cocher unique.
          - yes_no : pour une question à réponse « oui »/« non ».
          - drop_down_list : pour un choix unique dans une liste déroulante (options configurées ailleurs par l’administration).
          - multiple_drop_down_list : pour un choix multiple dans une liste déroulante (options configurées ailleurs par l’administration).

          Ce qui délimite les sections, c'est la position des champs "header_section" suivis des champs qui les suivent jusqu'à la prochaine "header_section".

          <schema>
          %<schema>s
          </schema>
      PROMPT
    end

    def sanitize_schema_for_prompt(schema)
      return schema unless schema.is_a?(Array)

      schema.map do |field|
        field.transform_values do |value|
          case value
          when Array
            Array(value).map { |choice| choice.is_a?(String) ? choice.gsub(DANGEROUS_CHARS, '').strip : choice }
          when String
            value.gsub(DANGEROUS_CHARS, '').strip
          else
            value
          end
        end
      end
    end
  end
end
