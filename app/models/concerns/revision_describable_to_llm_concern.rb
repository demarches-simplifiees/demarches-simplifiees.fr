# frozen_string_literal: true

module RevisionDescribableToLLMConcern
  def schema_to_llm
    revision_types_de_champ_public.map do |rtdc|
      {
        stable_id: rtdc.stable_id,
        type: rtdc.type_champ,
        libelle: rtdc.libelle,
        mandatory: rtdc.mandatory?,
        description: rtdc.description,
        choices: (rtdc.type_de_champ.drop_down_options if rtdc.type_de_champ.choice_type?),
        position: rtdc.position
      }.compact
    end
  end
end
