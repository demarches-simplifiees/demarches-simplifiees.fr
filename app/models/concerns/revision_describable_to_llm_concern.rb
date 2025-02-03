# frozen_string_literal: true

module RevisionDescribableToLLMConcern
  def schema_to_llm
    revision_types_de_champ_public.map do |tdc|
      {
        stable_id: tdc.stable_id,
        type: tdc.type_champ,
        libelle: tdc.libelle,
        mandatory: tdc.mandatory?,
        description: tdc.description
      }
    end
  end
end
