# frozen_string_literal: true

class LLM::ImproveStructureItemComponent < LLM::SuggestionItemComponent
  ACCEPTED_VALUE = LLMRuleSuggestionItem.verify_statuses.fetch(:accepted)
  SKIPPED_VALUE = LLMRuleSuggestionItem.verify_statuses.fetch(:skipped)

  def self.step_title
    "Amélioration de la structure"
  end

  def self.step_summary
    "Acceptez ou refusez les propositions de modifications de la structure de votre formulaire."
  end

  def original_tdc
    @original_tdc ||= tdc_for(item.stable_id)
  end

  def payload
    @payload ||= item.payload || {}
  end

  def op_kind
    item.op_kind
  end

  def position
    payload['position']
  end

  def mandatory?
    payload['mandatory']
  end

  def type_champ
    payload['type_champ']
  end

  def confidence_badge
    return if item.confidence.blank?

    content_tag(:span, "confiance: #{item.confidence}", class: 'fr-badge fr-mr-1w')
  end

  def checkbox(label_class: 'fr-label')
    safe_join([
      form_builder.check_box(:verify_status, {}, ACCEPTED_VALUE, SKIPPED_VALUE),
      form_builder.label(:verify_status, class: label_class) do
        capture { yield if block_given? }
      end,
    ])
  end
end
