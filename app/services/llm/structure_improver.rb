# frozen_string_literal: true

module LLM
  class StructureImprover < BaseImprover
    TOOL_DEFINITION = {
      type: 'function',
      function: {
        name: LLMRuleSuggestion.rules.fetch('improve_structure'),
        description: 'Propose une amélioration de la structure du formulaire.',
        parameters: {
          type: 'object',
          properties: {
            update: {
              type: 'object',
              description: 'Mise à jour d’un champ existant.',
              properties: {
                stable_id: { type: 'integer', description: 'Identifiant du champ à modifier.' },
                after_stable_id: { type: ['integer', 'null'], description: "Identifiant du champ après lequel ce champ doit être déplacé. Utiliser null UNIQUEMENT si le champ doit être positionné en premier, ou si c'est le premier champ d'une repetition. Si le champ est déplacé après un champ ajouté, utilise le generated_stable_id du champ ajouté précédement" },
                parent_id: { type: ['integer', 'null'], description: 'Identifiant de la repetition auquel le champ appartient. Utiliser null s’il n’appartient pas a une répétition' },
              },
              required: %w[stable_id after_stable_id],
            },
            add: {
              type: 'object',
              description: 'Ajout d’une nouvelle section.',
              properties: {
                generated_stable_id: { type: 'integer', description: "Identifiant stable unique du nouveau champ (section) à ajouter. Génère en entier negatif auto-décrémenté en partant de -1" },
                after_stable_id: { type: ['integer', 'null'], description: "Identifiant du champ après lequel ce champ doit être déplacé. Utiliser null UNIQUEMENT si le champ doit être positionné en premier, ou si c'est le premier champ d'une repetition." },
                libelle: { type: 'string', description: 'Libellé de la section (<= 80 chars, plain language)' },
                header_section_level: { type: 'integer', description: "Le niveau de la section (1 pour la plus haute hiérarchie, jusqu\'à 3)" },
                parent_id: { type: ['integer', 'null'], description: 'Identifiant de la repetition auquel le champ appartient. Utiliser null s’il n’appartient pas a une répétition' },
              },
              required: %w[generated_stable_id after_stable_id libelle header_section_level],
            },
            justification: { type: 'string' },
          },
          additionalProperties: false,
        },
      },
    }.freeze

    def system_prompt
      <<~TXT
        Tu es un assistant chargé d’améliorer la structure d’un formulaire administratif français.
        Tu peux ajouter des sections et réordonner des champs.
      TXT
    end

    # important: la position des champ existant est connue
    # quand on ajoute un champ, notre API interne le position en fonction du champ qui le prédède
    # il y a donc un non alignment dans nos interface a ce moment la
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
        Tu dois respecter strictement les règles suivantes pour améliorer la structure des formulaires administratifs français.

        ---

        ## 1. Organisation logique de l'information

        * Structure le formulaire de manière hiérarchique : commence par les informations générales, puis spécifiques.
        * Groupe les champs similaires ensemble (ex. : toutes les informations personnelles dans une section).
        * Utilise une progression logique : du général au particulier, en évitant les sauts brusques.
        * Respecte la pyramide inversée : place les éléments essentiels en haut.

        ---

        ## 2. Aller à l'essentiel

        * Priorise les données indispensables à la démarche administrative.
        * Évite les digressions : chaque section doit avoir un objectif clair.

        ---

        ## 3. Considération de l'usager

        * Adapte la structure au parcours usager : pense à l'ordre dans lequel l'usager remplit naturellement le formulaire.
        * Réduis la charge cognitive : limite le nombre de champs par section (idéalement 5-7 max).
        * Facilite la navigation : utilise des sections pour guider étape par étape.

        ---

        ## 4. Présentation visuelle et lisibilité

        * Ajoute des sections (header_section) pour aérer le formulaire et améliorer la lisibilité.
        * Utilise des niveaux de hiérarchie (1 à 3) pour structurer : niveau 1 pour les grandes parties, niveaux inférieurs pour les sous-sections.
        * Soigne l'espacement : évite les blocs denses de champs sans séparation.

        ---

        ## 5. Ordre et priorisation des champs

        * Place les champs obligatoires et essentiels en premier.
        * Ordonne logiquement : informations personnelles, puis contextuelles, puis justificatifs.
        * Utilise `update` pour repositionner les champs existants si nécessaire.
        * Utilise `add` pour introduire de nouvelles sections, en positionnant avec `after_stable_id`.

        ---

        ## 6. Vérification avant réponse

        Avant de proposer des changements, vérifie que :
        * La structure facilite le remplissage pour un usager non-expert.
        * Les sections sont pertinentes et non redondantes.
        * L'ordre respecte une logique administrative claire.
        * Les libellés de section sont concis (<= 80 caractères) et en langage simple.


        ---

        ## 7. Contraintes techniques

        * Ne deplace JAMAIS un champ en dehors de sa répétition.
        * Dans une répétition, la position des champs repart à 0 et est bornée dans celle ci.
        # Assures toi qu'un seul champ est a la position 0 dans une répétition.
        # Assures toi qu'un seul cahmp est a la position 0 hors répétition.

        ---

        Utilise l’outil #{TOOL_DEFINITION.dig(:function, :name)} pour chaque amélioration structurelle (ajout de section ou repositionnement).
      TXT
    end

    def build_item(args)
      if args['add']
        build_add_item(args)
      elsif args['update']
        build_update_item(args)
      end
    end

    def build_add_item(args)
      data = args['add'].is_a?(Hash) ? args['add'].dup : {}
      payload = data.compact
      payload['type_champ'] = 'header_section'

      {
        op_kind: 'add',
        stable_id: nil,
        payload: payload,
        verify_status: 'review',
        justification: args['justification'].to_s.presence,
      }
    end

    def build_update_item(args)
      data = args['update'].is_a?(Hash) ? args['update'].dup : {}
      stable_id = data['stable_id']
      payload = data.compact

      {
        op_kind: 'update',
        stable_id: stable_id,
        payload: payload,
        verify_status: 'review',
        justification: args['justification'].to_s.presence,
      }
    end
  end
end
