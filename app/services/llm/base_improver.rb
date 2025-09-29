# frozen_string_literal: true

module LLM
  class BaseImprover
    attr_reader :runner, :logger

    def initialize(runner: nil, logger: Rails.logger)
      @runner = runner
      @logger = logger
    end

    def generate_for(suggestion)
      messages = build_messages(suggestion)
      calls = run_tool_call(tool_definition: self.class::TOOL_DEFINITION, messages:)
      normalize_tool_calls(calls, suggestion.rule) { |args| build_item(args) }
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

    def build_messages(suggestion)
      revision = suggestion.procedure_revision
      schema = revision.schema_to_llm

      [
        { role: 'system', content: system_prompt },
        { role: 'user', content: format(schema_prompt, schema: JSON.dump(schema)) },
        { role: 'user', content: rules_prompt },
      ]
    end

    def run_tool_call(tool_definition:, messages:)
      return [] unless runner
      runner.call(messages:, tools: [tool_definition]) || []
    rescue => e
      logger.warn("[#{self.class.name}] tool call failed: #{e.class}: #{e.message}")
      []
    end

    def normalize_tool_calls(calls, tool_name)
      calls
        .filter { |call| call[:name] == tool_name }
        .map do |call|
          args = call[:arguments] || {}
          yield(args)
        end
        .compact
    end
  end
end
