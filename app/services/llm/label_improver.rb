# frozen_string_literal: true

module LLM
  # Orchestrates improve_label generation using tool-calling.
  class LabelImprover < BaseImprover
    TOOL_DEFINITION = {
      type: 'function',
      function: {
        name: LLMRuleSuggestion.rules.fetch('improve_label'),
        description: "Améliore les libellés & descriptions du formulaire en respectant les bonnes pratiques de conception d'un formulaire administratif français.",
        parameters: {
          type: 'object',
          properties: {
            update: {
              type: 'object',
              properties: {
                stable_id: { type: 'integer', description: 'Identifiant stable du champ cible' },
                libelle: { type: 'string', description: 'Nouveau libellé (<= 80 caractères, langage simple).' },
                description: { type: 'string', description: 'Nouvelle description idéalement (<= 160 caractères, langage simple). Pour les champ de type type_champ : carte, commune, date, datetime, decimal_number, dossier_link, email, epci, iban, multiple_drop_dow, phone, rna, rnf, siret, titre_identite : retourner null' },
                parent_id: { type: ['integer', 'null'], description: 'Identifiant stable du champ parent, ou null s’il n’y a pas de parent' },
                position: { type: ['integer'], description: 'Position du champ' },
              },
              required: %w[stable_id libelle position parent_id],
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
    # https://www.modernisation.gouv.fr/campus-de-la-transformation-publique/catalogue-de-ressources/outil/simplifier-les-documents
    #  - https://www.modernisation.gouv.fr/files/2021-06/aller_a_lessentiel_com.pdf
    #  - https://www.modernisation.gouv.fr/files/2021-06/des_mots_simples_tu_utiliseras_com.pdf
    #  - https://www.modernisation.gouv.fr/files/2021-06/avec_logique_linformation_tu_organiseras_com.pdf
    #  - https://www.modernisation.gouv.fr/files/2021-06/lusager_tu_considereras_com.pdf
    #  - https://www.modernisation.gouv.fr/files/2021-06/la_presentation_tu_soigneras_com.pdf
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
        * Les champs de type explication doivent expliquer précisément quoi faire, comment, et si nécessaire quand.

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
        * Le libelle des section (header_section) ne doivent JAMAIS être préfixé par un numéro car le système les gère automatiquement.

        ---

        ## 7. Vérification automatique avant réponse

        Avant de produire la version finale du texte, vérifier que :

        * L’action demandée est clairement décrite.
        * Aucun jargon, acronyme non défini ou terme technique n’est présent.
        * Les textes sont concis, lisibles et orientés vers l’action.
        * Le message principal est visible immédiatement.
        * La formulation n’excède pas une ou deux phrases, sauf exception nécessaire.

        ---

        ## 8. Regles d'accessibilité numérique (WCAG)
        * Ne JAMAIS indiquer quand les champs sont optionnels/facultatifs dans les libellés. Cette information est fournie automatiquement par le système.
        * Ne JAMAIS utilise email, courriel. Preférer adresse électronique.

        Utiliser l’outil #{TOOL_DEFINITION.dig(:function, :name)} pour chaque champ à améliorer (un appel par champ).
      TXT
    end

    def build_item(args)
      update = args['update'].is_a?(Hash) ? args['update'] : {}
      stable_id = update['stable_id'] || args['stable_id']
      libelle = (update['libelle'] || args['libelle']).to_s.strip
      description = (update['description'] || args['description'])
      position = (update['position'] || args['position'])
      parent_id = (update['parent_id'] || args['parent_id'])

      return nil if filter_invalid_llm_result(stable_id, libelle, description)

      {
        op_kind: 'update',
        stable_id: stable_id,
        payload: { 'stable_id' => stable_id, 'libelle' => libelle, 'description' => description, 'position' => position, 'parent_id' => parent_id }.compact,
        justification: args['justification'].to_s.presence,
      }
    end

    def filter_invalid_llm_result(stable_id, libelle, description)
      stable_id.nil? || libelle.blank?
    end
  end
end
