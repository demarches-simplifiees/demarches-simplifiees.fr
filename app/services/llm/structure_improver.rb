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
                position: { type: ['integer'], description: 'Position du champ' },
              },
              required: %w[position stable_id],
            },
            add: {
              type: 'object',
              description: 'Ajout d’une nouvelle section.',
              properties: {
                after_stable_id: { type: ['integer', 'null'], description: 'Identifiant du champ après lequel le champ à ajouter doit être positionné. Utiliser null UNIQUEMENT si le champ à ajouter doit être positionné en premier.' },
                position: { type: ['integer'], description: 'Position du champ' },
                libelle: { type: 'string', description: 'Libellé de la section (<= 80 chars, plain language)' },
                header_section_level: { type: 'integer', description: "Le niveau de la section (1 pour la plus haute hiérarchie, jusqu\'à 3)" },
              },
              required: %w[after_stable_id libelle header_section_level position],
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
        Tu peux ajouter des sections, réordonner des champs.
      TXT
    end

    def schema_prompt
      <<~TXT
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
      TXT
    end

    # important: la position des champ existant est connue
    # quand on ajoute un champ, notre API interne le position en fonction du champ qui le prédède
    # il y a donc un non alignment dans nos interface a ce moment la
    def rules_prompt
      <<~TXT
        Règles :
        - Positionne les champs essentiels en premier
        - Positionne les champs dans un ordre logique pour l’usager
        - Si tu modifie la position d’un champ existant ou si tu ajoutes une nouvelle section, tu dois changer la position de tous les champs
        - Deux champs ne peuvent pas avoir la même position
        - Afin de structurer le formulaire, tu peux ajouter des sections (type `header_section`)
          - Tu dois utiliser un `libelle` clairs et concis (<= 80 caractères).
          - Tu dois utiliser un `header_section_level` pour indiquer le niveau de la section (1 à 3).
        - Utilise `add` pour créer une nouvelle section.
          - Quand tu ajoutes un champ, positionne-le en utilisant `after_stable_id` qui est l'identifiant du champ qui le précède.
        - Utilise `update` pour repositionner un champ existant.
        - Fournis toujours une justification courte et une confiance 0..1.
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
      payload['after_stable_id'] = payload['after_stable_id'].to_i
      payload['type_champ'] = 'header_section'

      {
        op_kind: 'add',
        stable_id: nil,
        payload: payload,
        safety: 'review',
        justification: args['justification'].to_s.presence,
        confidence: args['confidence'],
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
        safety: 'review',
        justification: args['justification'].to_s.presence,
        confidence: args['confidence'],
      }
    end
  end
end
