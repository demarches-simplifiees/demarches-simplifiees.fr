# frozen_string_literal: true

class LLM::ImproveLabelItemComponent < LLM::SuggestionItemComponent
  ACCEPTED_VALUE = LLMRuleSuggestionItem.verify_statuses.fetch(:accepted)
  SKIPPED_VALUE = LLMRuleSuggestionItem.verify_statuses.fetch(:skipped)

  def render?
    original_tdc.present?
  end

  def original_tdc
    @original_tdc ||= tdc_for(item.stable_id)
  end

  def payload
    @payload ||= item.payload || {}
  end

  def libelle_changed?
    payload['libelle'].present? && payload['libelle'] != original_tdc.libelle
  end

  def confidence_badge
    return unless item.confidence.present?

    content_tag(:span, "confiance: #{item.confidence}", class: 'fr-badge')
  end

  def checkbox
    safe_join([
      form_builder.check_box(:verify_status, {}, ACCEPTED_VALUE, SKIPPED_VALUE),
      form_builder.label(:verify_status, class: 'fr-label') do
        capture { yield if block_given? }
      end,
    ])
  end
end
