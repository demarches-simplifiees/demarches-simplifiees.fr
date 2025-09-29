# frozen_string_literal: true

module LLM
  class StructureImprover < BaseImprover
    TOOL_NAME = 'improve_structure'

    TOOL_DEFINITION = {
      type: 'function',
      function: {
        name: TOOL_NAME,
        description: 'Propose une amélioration de la structure du formulaire.',
        parameters: {
          type: 'object',
          properties: {
            update: {
              type: 'object',
              description: 'Mise à jour d’un champ existant.',
              properties: {
                stable_id: { type: 'integer', description: 'Identifiant stable du champ à modifier.' },
                position: { type: ['integer'], description: 'Nouvelle position du champ à modifier.' },
                mandatory: { type: ['boolean'] },
              },
              required: %w[stable_id],
            },
            add: {
              type: 'object',
              description: 'Ajout d’une nouvelle section.',
              properties: {
                after_stable_id: { type: ['integer', 'null'], description: 'Identifiant stable du champ après lequel le champ à ajouter doit être positionné. Utiliser null si le champ à ajouter doit être positionné en premier.' },
                libelle: { type: 'string', description: 'Libellé de la section (<= 80 chars, plain language)' },
                description: { type: 'string', description: 'Explication de la section' },
              },
              required: %w[after_stable_id libelle],
            },
            justification: { type: 'string' },
            confidence: { type: 'number', minimum: 0, maximum: 1 },
          },
          additionalProperties: false,
        },
      },
    }.freeze

    CLASS_SUMMARY = <<~TEXT.squish.freeze
      Cette règle propose des améliorations non destructives à la structure du formulaire :
      - Place essential fields first, following user-centric logic
      - Add sections to structure the fields with appropriate level if necessary (level starts at 1)
      - Organize fields within sections for better flow
    TEXT

    class << self
      def summary = CLASS_SUMMARY
      def name = 'Amélioration de la structure'
      def key = 'structure_improve'
    end

    private

    def system_prompt
      <<~TXT
        Tu es un assistant chargé d’améliorer la structure d’un formulaire administratif français.
        Tu peux ajouter des sections, réordonner des champs ou ajuster leurs propriétés (mandatory).
      TXT
    end

    def schema_prompt
      <<~TXT
        Voici le schéma des champs (publics) du formulaire en JSON. Chaque entrée contient un identifiant unique (stable_id), un type, un libellé, la position, le caractère obligatoire (mandatory), et éventuellement une description.

        Les type de champ possibles sont :
        - header_section : pour structurer le formulaire en sections (aucune saisie attendue, uniquement un libelle et optinnelement un description).
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
        L'ordre des champs dans le schema est déterminé par leur position.

        <schema>
        %<schema>s
        </schema>
      TXT
    end

    def rules_prompt
      <<~TXT
        Règles :
        - Positionne les champs essentiels en premier
        - Positionne les champs dans un ordre logique pour l’usager
        - Utilise `add` pour créer une nouvelle section afin de structurer le formulaire et les champs.
          - Quand tu ajoutes un champ, positionne-le en utilisant `after_stable_id` pour repositionner un champ ou une section en fonction du stable_id du champ précédent (null pour premier).
        - Utilise `update` pour repositionner et la propriété position d'un champ existant
          - Utilise `position` pour repositionner un champ existant
          - Utilise `mandatory` pour rendre un champ obligatoire ou non
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
