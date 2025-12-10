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
        - Attention : conserve l'ordre des champs couplés en eux-mêmes par leurs libelle ex: "Nom de l'enfant 1", "Prénom de l'enfant 1", "Nom de l'enfant 2", "Prénom de l'enfant 2" doivent rester ensemble.

        ## 2. Présentation visuelle et lisibilité
        - Utilise les header_sections pour améliorer la lisibilité du formulaire.
        - Regroupe les champs similaires sous des sections appropriées.
        - Hiérarchise avec les niveaux (header_section_level : 1 = principal, 2 = sous-section, 3 = détail).
        - ⚠️ Règle stricte : N'ajoute jamais une header_section juste après une autre du même niveau (risque de hiérarchie plate).
        - ⚠️ Règle stricte sur les header_sections et les conditions d'affichage : Voir la section ## 4 pour les détails et exemples (risque de confusion si la section est affichée sans les champs conditionnés).
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
        - ⚠️ Règles strictes sur les repositionnements et les conditions : Lors de tout repositionnement de champs, vous devez absolument préserver les dépendances existantes. Un champ qui dépend d'un autre (via une condition d'affichage) doit toujours être placé après le champ référent (celui dont il dépend, identifiable par son stable_id dans la structure du formulaire). Cela garantit que la logique conditionnelle reste intacte.
        - De plus, gardez les champs dépendants proches de leurs référents pour améliorer la clarté et éviter la confusion pour l'utilisateur.
        - Interdiction absolue : Ne brisez jamais une condition existante en déplaçant un champ de manière à invalider sa dépendance.
        - Exemples :
          - Interdit : Déplacer un champ "Numéro de permis" (qui s'affiche seulement si "Avez-vous un véhicule ?" = oui) avant la question "Avez-vous un véhicule ?". Résultat : Le champ apparaît sans que la condition puisse être évaluée, brisant la logique.
          - Autorisé : Déplacer le champ "Numéro de permis" juste après "Avez-vous un véhicule ?", en gardant la proximité pour une meilleure lisibilité.
        - Cette règle assure que les formulaires conditionnels fonctionnent correctement et restent intuitifs.
        - ⚠️ Règle stricte sur les header_sections et les conditions d'affichage : Ne placez jamais une header_section (titre de section) juste avant un ou plusieurs champs qui dépendent d'une condition d'affichage. Sinon, le titre de section risquerait d'apparaître à l'écran sans que les champs associés ne soient visibles, créant une confusion pour l'utilisateur.
        - Vous pouvez ajouter des titres de sections uniquement devant des champs qui n'ont pas de conditions d'affichage (c'est-à-dire des champs toujours visibles).
        - Exemples :
          - Interdit : Ajouter une header_section "Informations complémentaires" juste avant un champ "Numéro de permis de conduire" qui s'affiche seulement si l'utilisateur répond "Oui" à la question "Avez-vous un véhicule ?". Résultat : Le titre apparaît, mais le champ reste caché, laissant une section vide.
          - Autorisé : Ajouter une header_section "Vos coordonnées" avant les champs "Nom" et "Prénom", qui sont toujours visibles (pas de condition). Cela améliore la structure sans risque de confusion.
        - Cette règle préserve la logique des formulaires conditionnels et évite des affichages incohérents.

        Utilise l’outil #{TOOL_DEFINITION.dig(:function, :name)} pour chaque amélioration. Justifie toujours tes choix dans la réponse.
      TXT
    end

    def build_item(args, tdc_index: {})
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
