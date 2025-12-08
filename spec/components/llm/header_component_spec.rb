# frozen_string_literal: true

RSpec.describe LLM::HeaderComponent, type: :component do
  let(:procedure) { create(:procedure) }
  let(:last_refresh) { Time.zone.local(2025, 10, 13, 14, 40) }
  let(:llm_rule_suggestion) do
    create(:llm_rule_suggestion,
      procedure_revision: procedure.draft_revision,
      rule: LLMRuleSuggestion.rules.fetch('improve_label'),
      schema_hash: 'schema-hash',
      state:).tap { _1.update!(created_at: last_refresh) }
  end

  let(:component) { described_class.new(llm_rule_suggestion:) }
  subject(:rendered_component) { render_inline(component) }

  context 'when state is pending' do
    let(:state) { :pending }

    it 'does not show status' do
      expect(rendered_component).not_to have_selector('.fr-icon-time-line')
      expect(rendered_component).to have_text('Comment fonctionne ce module')
    end
  end

  context 'when state is queued' do
    let(:state) { :queued }

    it 'shows queued status' do
      expect(rendered_component).to have_content('Analyse en cours…')
      expect(rendered_component).to have_text('Comment fonctionne ce module')
    end
  end

  context 'when state is completed' do
    let(:state) { :completed }
    it 'shows last refresh with timestamp' do
      expect(rendered_component).to have_content('Dernière recherche')
      expect(rendered_component).to have_content('lundi 13 octobre')
      expect(rendered_component).to have_text('Comment fonctionne ce module')
    end
  end
end
