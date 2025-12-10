# frozen_string_literal: true

class LLM::ConsolidateTypesItemComponent < LLM::SuggestionItemComponent
  def self.step_title
    "Consolidation des types de champs"
  end

  def render?
    original_tdc.present?
  end

  def op_kind
    item.op_kind
  end

  def type_champ_label(type_champ)
    I18n.t(type_champ, scope: [:activerecord, :attributes, :type_de_champ, :type_champs])
  end

  def new_type_champ_label
    type_champ_label(payload['type_champ'])
  end

  def original_type_champ_label
    type_champ_label(original_tdc.type_champ)
  end

  def checkbox(label_class: 'fr-label')
    safe_join([
      form_builder.check_box(:verify_status, { data: { action: "click->enable-submit-if-checked#click" } }, ACCEPTED_VALUE, SKIPPED_VALUE),
      form_builder.label(:verify_status, class: label_class) do
        capture { yield if block_given? }
      end,
    ])
  end
end
