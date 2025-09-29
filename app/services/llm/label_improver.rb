# frozen_string_literal: true

module LLM
  # Orchestrates improve_label generation using tool-calling.
  class LabelImprover < BaseImprover
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

    def system_prompt
      <<-ROLE
        Optimisation des formulaires en ligne (UX Writing)
        Tu es un assistant expert en UX Writing, en conception de formulaires en ligne et en simplification administrative.
        Ta mission est d’améliorer les libellés, descriptions, titres de section et explications d’un formulaire en ligne afin de les rendre plus clairs, plus simples, plus utiles et orientés vers l’action.
      ROLE
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
=======
    def build_item(args)
      update = args['update'].is_a?(Hash) ? args['update'] : {}
      stable_id = update['stable_id'] || args['stable_id']
      libelle = (update['libelle'] || args['libelle']).to_s.strip
      return if stable_id.nil? || libelle.blank?

      {
        op_kind: 'update',
        stable_id: stable_id,
        payload: { 'stable_id' => stable_id, 'libelle' => libelle },
>>>>>>> 7f33ed35bb (refactor(LabelImprover): extract LLM::BaseImprover in norder to share code between LabelImprover and upcoming StructureImprover)
        safety: 'safe',
        justification: args['justification'].to_s.presence,
        confidence: args['confidence'],
      }
<<<<<<< HEAD
>>>>>>> 4df4c0b58b (fixup! feat(LLM): wire first LLM calls to improve label of type de champ. So we glued : - an openai_client - a LLM::Runner (using the openai_client), it calls tools/returns tools results in a normalized way - LabelImprover that uses the runner to build payload that will be stored on LLMSuggestionItems)
=======
>>>>>>> 7f33ed35bb (refactor(LabelImprover): extract LLM::BaseImprover in norder to share code between LabelImprover and upcoming StructureImprover)
    end
  end
end
