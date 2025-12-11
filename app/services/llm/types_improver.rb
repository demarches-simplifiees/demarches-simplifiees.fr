# frozen_string_literal: true

module LLM
  class TypesImprover < BaseImprover
    TOOL_DEFINITION = {
      type: 'function',
      function: {
        name: LLMRuleSuggestion.rules.fetch('improve_types'),
        description: 'Propose un changement de type de champ pour une meilleure UX pour l\'usager et des données consolidées pour les instructeurs',
        parameters: {
          type: 'object',
          properties: {
            update: {
              type: 'object',
              description: 'Changement de type',
              properties: {
                stable_id: { type: 'integer', description: 'Identifiant du champ à modifier.' },
                type_champ: { type: 'string', description: 'Nouveau type du champ.' },
              },
              required: %w[stable_id type_champ],
            },
            justification: { type: 'string' },
          },
          additionalProperties: false,
        },
      },
    }.freeze

    def system_prompt
      <<~TXT
        Tu es un assistant expert chargé d'améliorer les types de champs d'un formulaire administratif français afin d'améliorer son ergonomie.
      TXT
    end

    def rules_prompt
      <<~TXT
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
        - siret : Numéro SIRET. Fournit automatiquement : raison sociale, SIREN, nom commercial, forme juridique, code NAF, libellé d'activité, N° TVA intracommunautaire, capital social, effectif, date de création, adresse du siège, état administratif.

        Référentiels externes :
        - rna : Répertoire National des Associations. Fournit : titre et objet de l'association, adresse normalisée, état administratif
        - rnf : Répertoire National des Fondations. Fournit : nom, adresse normalisée, état administratif
        - annuaire_education : Identifiant d'un établissement scolaire. Fournit : nom, adresse, commune, SIREN, académie, nature de l'établissement, type de contrat, nombre d'élèves, téléphone, email

        Nombres et dates :
        - decimal_number : Nombre décimal avec validation (min/max configurables)
        - integer_number : Nombre entier avec validation (min/max configurables). Ne PAS utiliser pour des numéros/codes etc… même s'ils ne contiennent que des chiffres.
        - formatted : Texte court avec contraintes de format, par exemple que des lettres ou chiffres. A n'utiliser que pour des codes, numéros administratifs, identifiants dont le format est bien connu.
        - date : Date seule avec sélecteur calendrier
        - datetime : Date et heure avec sélecteur

        Choix :
        - checkbox : Case à cocher unique (acceptation de conditions, CGU...). Si elle est obligatoire, bloque la soumission du formulaire si elle n'est pas cochée.
        - yes_no : Boutons radio pour une question à réponse binaire Oui/Non avec interface dédiée
        - drop_down_list : Choix unique dans une liste déroulante ou des boutons radio suivant la quantité de choix
        - multiple_drop_down_list : Choix multiples dans une liste sous forme de checkbox ou combobox suivant la quantité de choix

        ## Règles :
        - Utilise `update` pour modifier le type du champ (avec stable_id et type_champ)
        - Ignore les champs qui sont à garder tels quels
        - Ne suggère pas de transformation inutile, par exemple ne change pas un champ "Commune" en "Adresse" si seule la commune est demandée.

        ## Justification:
        - Quand un champ doit être modifié, fournis une courte justification qui sera affichée à l'administrateur pour lui expliquer les raisons pratiques du changement.
        - le texte ne doit pas comporter les libellés trop longs de champs
        - le texte ne doit pas comporter de détails techniques (HTML, code du type de champ, ids etc…).

        ## Concentre-toi sur les gains concrets :
        - Validation automatique (email, iban, siret)
        - Enrichissement de données (siret → données entreprise, address → commune/département/région)
        - Simplification pour l'usager (UX adaptée pour chaque champ, meilleure accessibilité)

        Utilise l'outil #{TOOL_DEFINITION.dig(:function, :name)} pour chaque proposition (un appel par changement).
        Ne réponds rien si tous les types sont déjà corrects.
      TXT
    end

    def build_item(args, tdc_index: {})
      build_update_item(args, tdc_index) if args['update']
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

    def valid_type_champ?(type_champ)
      TypeDeChamp.type_champs.key?(type_champ.to_s)
    end
  end
end
