# frozen_string_literal: true

module RevisionDescribableToLLMConcern
  def schema_to_llm
    revision_types_de_champ.includes(:parent, :type_de_champ)
      .filter(&:public?).map do |rtdc|
        {
          stable_id: rtdc.stable_id,
          type: rtdc.type_champ,
          libelle: rtdc.libelle,
          mandatory: rtdc.mandatory?,
          description: rtdc.description,
          total_choices: (rtdc.type_de_champ.drop_down_options&.size if rtdc.type_de_champ.choice_type?),
          sample_choices: (rtdc.type_de_champ.drop_down_options.take(10) if rtdc.type_de_champ.choice_type?),
          choices_dynamic: (rtdc.type_de_champ.referentiel.present? ? true : nil),
          position: rtdc.position,
          parent_id: rtdc.parent&.stable_id,
          header_section_level: (rtdc.type_de_champ.header_section_level if rtdc.type_de_champ.header_section?),
          # absolute_level: (rtdc.type_de_champ.header_section? ? rtdc.type_de_champ.level_for_revision(self) : nil),
          display_condition: rtdc.type_de_champ.condition.to_h,
        }.compact
      end
  end
end
