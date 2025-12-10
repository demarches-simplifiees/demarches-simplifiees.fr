# frozen_string_literal: true

module LLM
  class TypesConsolidator < BaseImprover
    TOOL_DEFINITION = {
      type: 'function',
      function: {
        name: LLMRuleSuggestion.rules.fetch('consolidate_types'),
        description: 'Propose un changement de type de champ pour une meilleure UX pour l\'usager et des données consolidées pour les instructeurs',
        parameters: {
          type: 'object',
          properties: {
            update: {
              type: 'object',
              description: 'Changement de type',
              properties: {
                stable_id: { type: 'integer', description: 'Identifiant du champ à modifier.' },
                type_champ: { type: 'string', description: 'Nouveau type de champ.' },
              },
              required: %w[stable_id type_champ],
            },
            destroy: {
              type: 'object',
              description: 'Suppression d\'un champ devenu redondant après consolidation, ou demandant une information remontée via le champ Adresse, SIRET, …',
              properties: {
                stable_id: { type: 'integer', description: 'Identifiant du champ à supprimer.' },
              },
              required: %w[stable_id],
            },
            justification: { type: 'string' },
          },
          additionalProperties: false,
        },
      },
    }.freeze

    def system_prompt
      <<~TXT
        Tu es un assistant chargé d'améliorer les types de champs d'un formulaire administratif français.

        Contexte de la démarche :
        - Titre : %{libelle}
        - Description : %{description}

        Principe "Dites-le-nous une fois" (DLNUF) : l'administration ne doit pas redemander des informations déjà collectées.

        Champs collectés à l'entrée de la démarche :
        %{champs_entree}
      TXT
    end

    def schema_prompt
      <<~TXT
        Voici le schéma des champs (publics) du formulaire en JSON.

        <schema>
        %<schema>s
        </schema>

        Types de champs spécialisés disponibles :

        Identification et état civil :
        - civilite : Choix « Madame » ou « Monsieur »
        - email : Adresse électronique avec validation du format
        - phone : Numéro de téléphone avec validation (formats français et internationaux)

        Localisation (avec auto-complétion et données enrichies) :
        - address : Adresse postale complète. Fournit automatiquement : commune, code postal, département, région, pays, code INSEE
        - communes : Sélection d'une commune française. Fournit : nom, code INSEE, code postal, département
        - departements : Sélection d'un département français (code et nom)
        - regions : Sélection d'une région française (code et nom)
        - pays : Sélection d'un pays parmi la liste des pays ACTUELS seulement. Ne convient PAS pour les pays de naissance (pays historiques absents)
        - carte : Sélection de point, segment, polygones, parcelles cadastrale ou agricoles sur un fond de carte

        Paiement et identification d'entités :
        - iban : Numéro IBAN avec validation du format bancaire international
        - siret : Numéro SIRET. Fournit automatiquement via API Entreprise : raison sociale, SIREN, nom commercial, forme juridique, code NAF, libellé d'activité, N° TVA intracommunautaire, capital social, effectif, date de création, adresse du siège, état administratif.

        Référentiels externes :
        - rna : Répertoire National des Associations. Fournit : titre et objet de l'association, adresse normalisée, état d'aministratif
        - rnf : Répertoire National des Fondations. Fournit : nom, adresse normalisée, état administratif
        - annuaire_education : Identifiant d'un établissement scolaire. Fournit : nom, adresse, commune, SIREN, académie, nature de l’établissement, type de contrat, nombre d'élèves, téléphone, email

        Nombres et dates :
        - decimal_number : Nombre décimal avec validation (min/max configurables)
        - integer_number : Nombre entier avec validation (min/max configurables)
        - formatted : Texte court avec contraintes de format, par exemple que des lettres ou chiffres. Options : letters_accepted, numbers_accepted, special_characters_accepted
        - date : Date seule avec sélecteur calendrier
        - datetime : Date et heure avec sélecteur

        Choix :
        - checkbox : Case à cocher unique (acceptation de conditions, CGU...)
        - yes_no : Boutons radio pour une question à réponse binaire Oui/Non avec interface dédiée
        - drop_down_list : Choix unique dans une liste déroulante ou des boutons radio suivant la quantité de choix
        - multiple_drop_down_list : Choix multiples dans une liste sous forme de checkbox ou combobox suivant la quantité de choix
      TXT
    end

    def rules_prompt
      <<~TXT
        ## Règles :
        - Utilise `update` pour modifier le type du champ (avec stable_id et type_champ)
        - Utilise `destroy` pour supprimer un champ afin de respecter le DLNUF
        - Ignore les champs qui sont à garder tels quels

        ## Justification:
        - Quand un champ doit être modifié, fournis une courte justification courte qui sera affichée à l'administrateur pour lui expliquer les raisons pratiques du changement ou de la suppression.
        - le texte ne doit pas comporter les libellés trop longs de champs
        - le texte ne doit pas comporter de détails techniques (HTML, code du type de champ, ids etc…).

        ## Consolidation de champs :
        Les types address et siret fournissent automatiquement de nombreuses informations s'ils ont été demandés auparavant.
        Tu peux proposer de consolider des champs séparés en un seul champ enrichi.
        Règle critique : Les champs à consolider doivent concerner le MÊME sujet/contexte.
        Exemple : "Adresse de résidence" + "Commune de résidence" → on garde le champ adresse mais on supprime le champ commune

        ## Concentre-toi sur les gains concrets :
        - Validation automatique (email, iban, siret)
        - Enrichissement de données (siret → données entreprise, address → commune/département/région)
        - Simplification pour l'usager (UX adaptée pour chaque champ, meilleure accessibilité)

        Utilise l'outil #{TOOL_DEFINITION.dig(:function, :name)} pour chaque proposition (un appel par changement).
      TXT
    end

    def build_item(args, tdc_index: {})
      if args['destroy']
        build_destroy_item(args)
      elsif args['update']
        build_update_item(args, tdc_index)
      end
    end

    private

    def build_update_item(args, tdc_index)
      data = args['update']
      return unless data.is_a?(Hash)

      stable_id = data['stable_id']
      type_champ = data['type_champ']

      return if stable_id.nil? || type_champ.blank?
      return unless valid_type_champ?(type_champ)

      original_tdc = tdc_index[stable_id]
      return if original_tdc && original_tdc.type_champ == type_champ

      {
        op_kind: 'update',
        stable_id:,
        payload: { 'stable_id' => stable_id, 'type_champ' => type_champ },
        verify_status: 'pending',
        justification: args['justification'].presence,
      }
    end

    def build_destroy_item(args)
      data = args['destroy']
      stable_id = data.is_a?(Hash) ? data['stable_id'] : data

      return if stable_id.nil?

      result = {
        op_kind: 'destroy',
        stable_id:,
        payload: { 'stable_id' => stable_id },
        verify_status: 'pending',
        justification: args['justification'].presence,
      }

      result
    end

    def valid_type_champ?(type_champ)
      TypeDeChamp.type_champs.key?(type_champ.to_s)
    end
  end
end
