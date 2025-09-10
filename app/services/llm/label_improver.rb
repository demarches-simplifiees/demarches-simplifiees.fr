# frozen_string_literal: true

module LLM
  # Orchestrates improve_label generation using tool-calling.
  class LabelImprover
    TOOL_DEFINITION = {
      type: 'function',
      function: {
        name: LLMRuleSuggestion.rules.fetch('improve_label'),
        description: "Améliore les libéllés du formulaire en respectant les bonne pratique de conception d'un formulaire administratif français.",
        parameters: {
          type: 'object',
          properties: {
            update: {
              type: 'object',
              properties: {
                stable_id: { type: 'integer', description: 'Identifiant stable du champ cible' },
                libelle: { type: 'string', description: 'Nouveau libellé (<= 80 caractères, langage simple)' },
                description: { type: 'string', description: 'Nouvelle description idéalement (<= 160 caractères, langage simple)' },
                position: { type: ['integer'], description: 'Position du champ' },
              },
              required: %w[stable_id libelle],
            },
            justification: { type: 'string', description: 'Raison courte du changement' },
          },
          required: %w[update],
        },
      },
    }.freeze

    def initialize(runner: nil, logger: Rails.logger)
      @runner = runner
      @logger = logger
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
        { role: 'user', content: rules_prompt },
      ]
    end

    def system_prompt
      <<-ROLE
        Optimisation des formulaires en ligne (UX Writing)
        Tu es un assistant expert en UX Writing, en conception de formulaires en ligne et en simplification administrative.
        Ta mission est d’améliorer les libellés, descriptions, titres de section et explications d’un formulaire en ligne afin de les rendre plus clairs, plus simples, plus utiles et orientés vers l’action.
      ROLE
    end

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

    # https://www.modernisation.gouv.fr/files/2021-06/avec_logique_linformation_tu_organiseras_com.pdf
    # https://www.modernisation.gouv.fr/files/Campus-de-la-transformation/Guide-kit-formulaire.pdf
    # https://www.modernisation.gouv.fr/files/2021-06/avec_logique_linformation_tu_organiseras_com.pdf
    def rules_prompt
      <<~TXT
        Tu dois respecter strictement les règles suivantes.

        ---

        ## 1. Orientation usager

        * Adapter la formulation au niveau de compréhension d’un usager non-expert.
        * Employer un ton bienveillant et non culpabilisant.
        * Ne jamais supposer de connaissances juridiques, techniques ou administratives.

        ---

        ## 2. Clarté immédiate (formulaire = 1 message → 1 action)

        * Le libellé (libelle) d’un champ doit indiquer clairement ce que l’usager doit saisir.
        * Le texte d’aide (description) doit lever une ambiguïté, pas ajouter d’informations inutiles.
        * Les explication (type de champ explication) doivent expliquer précisément quoi faire, comment, et si nécessaire quand.

        ---

        ## 3. Simplification du langage

        * Utiliser des mots simples, concrets et courants.
        * Éviter le jargon, les formulations administratives ou juridiques.
        * Utiliser un seul mot pour un même concept (pas de synonymes).
        * Éviter les mots à double sens.
        * Écrire les nombres en chiffres (ex : « 2 documents »).
        * Supprimer les mots inutiles, tournures longues et adverbes superflus.
        * Éviter les acronymes ; si nécessaire, les définir systématiquement.

        Exemples à éviter : « veuillez », « conformément à », « procéder à ».
        Préférer : « envoyez », « sélectionnez », « indiquez ».

        ---

        ## 4. Simplicité des phrases

        * Phrases courtes (idéalement moins de 12 mots).
        * Une seule idée par phrase.
        * Préférence pour la forme active.
        * Syntaxe directe : sujet – verbe – complément.
        * Éviter les parenthèses et les doubles négations.

        ---

        ## 5. Faciliter le passage à l’action

        * Indiquer clairement les documents requis, formats attendus, dates limites et contraintes éventuelles.
        * Fournir listes, étapes ou checklists lorsque pertinent.
        * Utiliser l’impératif bienveillant pour les actions : « Téléchargez », « Indiquez », « Sélectionnez ».

        ---

        ## 6. Lisibilité visuelle (sous forme de suggestions)

        Le modèle peut suggérer :

        * L’aération des sections (paragraphes courts, espaces).
        * Des formulations plus courtes et adaptées aux interfaces.

        ---

        ## 7. Vérification automatique avant réponse

        Avant de produire la version finale du texte, vérifier que :

        * L’action demandée est clairement décrite.
        * Aucun jargon, acronyme non défini ou terme technique n’est présent.
        * Les textes sont concis, lisibles et orientés vers l’action.
        * Le message principal est visible immédiatement.
        * La formulation n’excède pas une ou deux phrases, sauf exception nécessaire.

        ---

        Utiliser l’outil #{TOOL_DEFINITION.dig(:function, :name)} pour chaque champ à améliorer (un appel par champ).
      TXT
    end

<<<<<<< HEAD
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
            confidence: args['confidence'],
          }
        end
        .compact
=======
    def build_item(args)
      update = args['update'].is_a?(Hash) ? args['update'] : {}
      stable_id = update['stable_id'] || args['stable_id']
      libelle = (update['libelle'] || args['libelle']).to_s.strip
      description = (update['description'] || args['description']).to_s.strip
      position = (update['position'] || args['position']).to_i
      return if stable_id.nil? || libelle.blank?

      {
        op_kind: 'update',
        stable_id: stable_id,
        payload: { 'stable_id' => stable_id, 'libelle' => libelle, 'description' => description, 'position' => position },
        safety: 'safe',
        justification: args['justification'].to_s.presence,
        confidence: args['confidence'],
      }
>>>>>>> 4df4c0b58b (fixup! feat(LLM): wire first LLM calls to improve label of type de champ. So we glued : - an openai_client - a LLM::Runner (using the openai_client), it calls tools/returns tools results in a normalized way - LabelImprover that uses the runner to build payload that will be stored on LLMSuggestionItems)
    end
  end
end
