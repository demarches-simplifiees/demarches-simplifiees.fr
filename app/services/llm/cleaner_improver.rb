# frozen_string_literal: true

module LLM
  class CleanerImprover < BaseImprover
    TOOL_DEFINITION = {
      type: 'function',
      function: {
        name: LLMRuleSuggestion.rules.fetch('cleaner'),
        description: 'Propose la suppression d\'un champ redondant',
        parameters: {
          type: 'object',
          properties: {
            destroy: {
              type: 'object',
              description: 'Suppression d\'un champ devenu redondant ou demandant une information déjà remontée via le champ Adresse, SIRET, …',
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
        Tu es un assistant chargé d'identifier les champs redondants d'un formulaire administratif français.

        Principe "Dites-le nous une fois" (DLNUF) : l'administration ne doit pas redemander des informations déjà collectées soit à l'entrée du formulaire, soit par un champ qui collecte des informations complémentaires.
      TXT
    end

    def rules_prompt
      <<~TXT
        Types de champs spécialisés qui fournissent des données enrichies :

        Localisation (avec auto-complétion et données enrichies) :
        - address : Adresse postale complète avec autocomplete. Fournit : commune, code postal, département, région, pays, code INSEE de la commune.
        - communes : Sélection d'une commune française. Fournit : nom, code postal, département, code INSEE

        Identification d'entités :
        - siret : Numéro SIRET d'une entreprise. Fournit automatiquement et exclusivement : raison sociale, SIREN, nom commercial, forme juridique, code et libellé NAF, adresse normalisée de l'établissement, adresse normalisée du siège social, N° TVA intracommunautaire, capital social, code effectif, date de création, état administratif.
        - rna : Répertoire National des Associations. Fournit : nom de l'association, titre et objet de l'association, adresse normalisée, état administratif
        - rnf : Répertoire National des Fondations. Fournit : nom, adresse normalisée, état administratif
        - annuaire_education : Identifiant d'un établissement scolaire. Fournit : nom de l'établissement, adresse normalisée, académie, nature de l'établissement, téléphone, email, site internet.

        Une "adresse normalisée" fournit ces informations:
        - numéro, nom de la voie
        - code postal
        - nom de la commune et son code INSEE
        - département

        ## Règles :
        - Identifie les champs qui demandent une information déjà disponible via un autre champ du formulaire plus haut dans la démarche.
        - Utilise `destroy` pour proposer la suppression d'un champ redondant

        ## Exemples de redondance :
        - Un champ "Commune" quand un champ "Adresse" existe (l'adresse fournit automatiquement la commune)
        - Un champ "Département" quand un champ "Adresse" ou "Commune" existe
        - Un champ "Raison sociale", "Adresse du siège" ou "Date de création" quand un champ "SIRET" existe

        ## Règle critique :
        - Ne supprime JAMAIS un champ qui sert de condition d'affichage pour d'autres champs: cela les rendrait invalides.
        - Les champs à supprimer doivent concerner le MÊME sujet/contexte.
        Exemple : "Adresse de résidence" + "Commune de résidence" → supprimer le champ commune
        Contre-exemple : "Adresse de résidence" + "Commune de naissance" → NE PAS supprimer (sujets différents)

        ## Justification:
        - Fournis une justification courte expliquant quel champ fournit déjà l'information
        - Le texte ne doit pas comporter de détails ou noms techniques.

        Utilise l'outil #{TOOL_DEFINITION.dig(:function, :name)} pour chaque proposition (un appel par suppression).
        Ne réponds rien s'il n'y a aucun champ redondant.
      TXT
    end

    def build_item(args, tdc_index: {})
      build_destroy_item(args, tdc_index:) if args['destroy']
    end

    private

    def build_destroy_item(args, tdc_index:)
      data = args['destroy']
      stable_id = data.is_a?(Hash) ? data['stable_id'] : data

      return if stable_id.nil?
      return if used_as_condition_source?(stable_id, tdc_index)

      {
        op_kind: 'destroy',
        stable_id:,
        payload: { 'stable_id' => stable_id },
        verify_status: 'pending',
        justification: args['justification'].presence,
      }
    end

    def used_as_condition_source?(stable_id, tdc_index)
      tdc_index.values.any? do |tdc|
        tdc.condition&.sources&.include?(stable_id)
      end
    end
  end
end
