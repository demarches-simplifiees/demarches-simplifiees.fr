# frozen_string_literal: true

module RevisionDescribableToLLMConcern
  def schema_to_llm
    revision_types_de_champ.includes(:parent)
      .filter(&:public?).map do |rtdc|
        {
          stable_id: rtdc.stable_id,
          type: rtdc.type_champ,
          libelle: rtdc.libelle,
          mandatory: rtdc.mandatory?,
          description: rtdc.description,
          choices: (rtdc.type_de_champ.drop_down_options if rtdc.type_de_champ.choice_type?),
          position: rtdc.position,
          parent_id: rtdc.parent&.stable_id,
        }.compact
      end
  end

  def procedure_context_to_llm
    champs_entree = if procedure.for_individual
      "- Civilité, nom et prénom du DEMANDEUR"
    else
      "- SIRET de l'ETABLISSEMENT (fournit automatiquement ~20 informations : raison sociale, adresse, forme juridique, NAF, etc.)"
    end

    {
      libelle: procedure.libelle,
      description: procedure.description,
      for_individual: procedure.for_individual,
      champs_entree:,
    }
  end
end
