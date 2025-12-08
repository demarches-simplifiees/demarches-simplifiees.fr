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
              description: "Mise à jour d'un champ ou d'un header_section.",
              properties: {
                stable_id: { type: 'integer', description: 'Identifiant du champ à modifier.' },
                after_stable_id: { type: ['integer', 'null'], description: "Identifiant du champ après lequel ce champ doit être déplacé. Utiliser null UNIQUEMENT si le champ doit être positionné en premier, ou si c'est le premier champ d'une repetition. Si le champ est déplacé après un champ ajouté, utilise le generated_stable_id du champ ajouté précédement" },
                libelle: { type: ['string', 'null'], description: "Le nouveau libellé de la section (<= 80 chars, plain language) si il faut le header_section. Utiliser null si le champ n'est pas un header_section" },
                parent_id: { type: ['integer', 'null'], description: 'Identifiant de la repetition auquel le champ appartient. Utiliser null s’il n’appartient pas a une répétition' },
                header_section_level: { type: ['integer', 'null'], description: "Le nouveau niveau de la section (1 pour la plus haute hiérarchie, jusqu\'à 3), uniquement si le champ est de type header_section" },
              },
              required: %w[stable_id after_stable_id],
            },
            add: {
              type: 'object',
              description: 'Ajout d’une nouvelle header_section.',
              properties: {
                generated_stable_id: { type: 'integer', description: "Identifiant stable unique du nouveau champ (section) à ajouter. Génère en entier negatif auto-décrémenté en partant de -1" },
                after_stable_id: { type: ['integer', 'null'], description: "Identifiant du champ après lequel ce champ doit être déplacé. Utiliser null UNIQUEMENT si le champ doit être positionné en premier, ou si c'est le premier champ d'une repetition." },
                libelle: { type: 'string', description: 'Libellé de la section (<= 80 chars, plain language)' },
                header_section_level: { type: ['integer', 'null'], description: "Le niveau de la section (1 pour la plus haute hiérarchie, jusqu\'à 3), uniquement si le champ est de type header_section" },
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
        Tu es un assistant expert en simplification administrative française. Ton objectif : améliorer la structure des formulaires pour faciliter le parcours usager, en ajoutant des sections et réordonnant les champs selon les principes de logique, d'essentiel et de présentation.
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

        ## Outils autorisés
        - Utilise `update` pour repositionner un champ/section existant (si nécessaire).
        - Utilise `add` pour ajouter une nouvelle header_section (si nécessaire). Génère des `generated_stable_id` négatifs uniques (e.g., -1, -2).

        ## 1. Organisation logique de l'information
        - Respecte la pyramide inversée : place les champs essentiels en haut.
        - Ordonne logiquement : informations personnelles d'abord, puis contextuelles.
        - L'ordre respecte une logique administrative claire.
        - Sépare les champs avec des header_sections pour clarifier les parties du formulaire.

        ## 2. Présentation visuelle et lisibilité
        - Utilise les header_sections pour et améliorer la lisibilité du formulaire.
        - Regroupe les champs similaires sous des sections appropriées.
        - Hiérarchise avec les niveaux (header_section_level : 1 = principal, 2 = sous-section, 3 = détail).
        - ⚠️ Règle stricte : N'ajoute jamais une header_section juste après une autre du même niveau (risque de hiérarchie plate).
        - ⚠️ Règle stricte : N'ajoute jamais une header_section pour structurer des champs conditionnels uniquement (risque de confusion).
        - Évite deux sections consécutives sans champ entre elles (préférence, pas interdiction absolue).

        ## 3. Vérifications avant toute proposition
        - Vérifie la pertinence : Les header_sections ajoutées doivent être utiles et non redondantes.
        - Vérifie la clarté : les champs dans les header_sections doivent être cohérents avec le libellé de la section.
        - Libellés : Concis (<= 80 caractères), en langage simple (e.g., "Vos coordonnées" au lieu de "Données d'identification utilisateur").
        - ⚠️ Interdiction : Ne déplace jamais un champ hors de sa répétition (respecte parent_id).
        - Cohérence des niveaux : Les header_sections doivent suivre une progression logique (1 avant 2, etc.).
        - Ordre cohérent : Chaque `after_stable_id` référencé une seule fois.

        ## 4. Logique conditionnelle (display_condition)
        - Les champs peuvent dépendre d'autres via des conditions (e.g., afficher "Numéro de permis" seulement si "Avez-vous un véhicule ?" = oui).
        - Opérateurs : Logic::Eq (égal), Logic::NotEq (différent), Logic::LessThan (inférieur), Logic::GreaterThan (supérieur), Logic::And (et), Logic::Or (ou).
        - Structure : Hash avec "term" (opérateur), "left"/"right" pour binaires, "operands" pour And/Or.
        - Exemple concret : {"term": "Logic::Eq", "left": {"term": "Logic::ChampValue", "stable_id": 123}, "right": {"term": "Logic::Constant", "value": "oui"}}.
        - ⚠️ Règles strictes : Lors de repositionnements, préserve les dépendances – un champ conditionnel DOIT rester après ses référents. Garde les champs dépendants proches pour la clarté. Interdiction : Ne brise jamais une condition existante.

        Utilise l’outil #{TOOL_DEFINITION.dig(:function, :name)} pour chaque amélioration. Justifie toujours tes choix dans la réponse.
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
