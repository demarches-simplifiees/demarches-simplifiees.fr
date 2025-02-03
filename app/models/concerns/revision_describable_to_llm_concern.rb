# frozen_string_literal: true

module RevisionDescribableToLLMConcern
  def schema_to_llm
    revision_types_de_champ
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
end
