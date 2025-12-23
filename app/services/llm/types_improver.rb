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
                options: {
                  type: 'object',
                  description: <<~DESC.squish,
                    Options spécifiques au type de champ.
                    Pour formatted, at least one of: letters_accepted (boolean), numbers_accepted (boolean), special_characters_accepted (boolean), min_character_length (integer), max_character_length (integer).
                    Pour integer_number/decimal_number: positive_number (boolean), min_number (number), max_number (number).
                    Pour date/datetime: date_in_past (boolean), start_date (string ISO), end_date (string ISO).
                  DESC
                  additionalProperties: false,
                },
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
        - formatted : UNIQUEMENT pour des codes/identifiants ayant un format standardisé clairement connu (code postal, numéro précis, immatriculation…). Ne PAS utiliser pour limiter la longueur d'un texte libre ou remplacer un champ texte/nombre/date classique ou plus spécifique. L'interface de saisie reste un input texte normal.
        - date : Date seule avec sélecteur calendrier
        - datetime : Date et heure avec sélecteur

        Choix :
        - checkbox : Case à cocher unique (acceptation de conditions, CGU...). Si elle est obligatoire, bloque la soumission du formulaire si elle n'est pas cochée.
        - yes_no : Boutons radio pour une question à réponse binaire Oui/Non avec interface dédiée
        - drop_down_list : Choix unique dans une liste déroulante ou des boutons radio suivant la quantité de choix
        - multiple_drop_down_list : Choix multiples dans une liste sous forme de checkbox ou combobox suivant la quantité de choix

        ## Options par type de champ:

        Certains types de champs prennent des options.

        Pour "formatted" (codes/identifiants à format connu) :
        - letters_accepted (boolean): accepter les lettres.
        - numbers_accepted (boolean): accepter les chiffres.
        - special_characters_accepted (boolean): accepter les caractères spéciaux.
        - min_character_length (integer): longueur minimale
        - max_character_length (integer): longueur maximale

        IMPORTANT: N'utiliser "formatted" QUE si le champ correspond à un code/identifiant normalisé dont le format est bien défini.
        Ne PAS utiliser pour : un nom, un titre, une description, un commentaire, une quantité, ou tout texte libre.
        Au moins une des options *_accepted doit être true.

        Exemples valides:
        - Code postal français: { numbers_accepted: true, letters_accepted: false, special_characters_accepted: false, min_character_length: 5, max_character_length: 5 }
        - Numéro de parcelle cadastrale: { letters_accepted: false, numbers_accepted: true, special_characters_accepted: false }

        Pour "integer_number" / "decimal_number" :
        - positive_number (boolean): n'accepter que les valeurs positives
        - min_number (number): valeur minimale optionelle
        - max_number (number): valeur maximale optionelle

        Pour "date" / "datetime" :
        - date_in_past (boolean): n'accepter que les dates passées
        - start_date (string ISO): date minimale (ex: "2020-01-01")
        - end_date (string ISO): date maximale

        Note: Les options fournies seront fusionnées avec les options existantes du champ.
        Ne fournis que les options que tu souhaites modifier. Les options actuelles sont visibles dans le schéma du formulaire.

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

      options = sanitize_options(type_champ, data['options'])

      payload = { 'stable_id' => stable_id, 'type_champ' => type_champ }
      payload['options'] = options if options.present?

      {
        op_kind: 'update',
        stable_id:,
        payload:,
        verify_status: 'pending',
        justification: args['justification'].presence,
      }
    end

    def valid_type_champ?(type_champ)
      TypeDeChamp.type_champs.key?(type_champ.to_s)
    end

    def sanitize_options(type_champ, options)
      return nil if options.blank? || !options.is_a?(Hash)

      allowed_keys = TypeDeChamp::OPTS_BY_TYPE[type_champ.to_s]
      return nil if allowed_keys.blank?

      options.slice(*allowed_keys.map(&:to_s)).presence
    end
  end
end
