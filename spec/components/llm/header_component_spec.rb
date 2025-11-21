# frozen_string_literal: true

RSpec.describe LLM::HeaderComponent, type: :component do
  let(:procedure) { create(:procedure) }
  let(:last_refresh) { Time.zone.local(2025, 10, 13, 14, 40) }
  let(:llm_rule_suggestion) do
    create(:llm_rule_suggestion,
      procedure_revision: procedure.draft_revision,
      rule: LLMRuleSuggestion.rules.fetch('improve_label'),
      schema_hash: 'schema-hash',
      state: 'completed').tap { _1.update!(created_at: last_refresh) }
  end

  let(:component) { described_class.new(llm_rule_suggestion:) }
  subject(:rendered_component) { render_inline(component) }

  describe '#last_suggestion_created_at_tag' do
    context 'when llm_rule_suggestion is persisted' do
      it 'returns a tag with timestamp' do
        expect(rendered_component).to have_css('.fr-hint-text')
        expect(rendered_component).to have_content(I18n.t('llm.stepper_component.last_refresh', timestamp: I18n.l(llm_rule_suggestion.created_at, format: :llm_stepper_last_refresh)))
      end
    end

    context 'when llm_rule_suggestion is not persisted' do
      let(:llm_rule_suggestion) { build(:llm_rule_suggestion) }

      it 'returns a tag with no suggestion message' do
        expect(rendered_component).to have_css('.fr-hint-text')
        expect(rendered_component).to have_content(I18n.t('llm.stepper_component.no_suggestion_yet'))
      end
    end
  end
end
