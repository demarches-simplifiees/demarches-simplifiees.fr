# frozen_string_literal: true

RSpec.describe LLM::SuggestionFormComponent, type: :component do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :text, libelle: 'Nom' }]) }
  let(:revision_coordinate) { procedure.draft_revision.revision_types_de_champ_public.first }
  let(:stable_id) { revision_coordinate.stable_id }
  let(:rule) { LLMRuleSuggestion.rules.fetch('improve_label') }
  let(:llm_rule_suggestion) do
    create(:llm_rule_suggestion,
      procedure_revision: procedure.draft_revision,
      rule: rule,
      schema_hash: 'schema-hash',
      state: 'completed')
  end

  before do
    create(:llm_rule_suggestion_item,
      llm_rule_suggestion: llm_rule_suggestion,
      stable_id: stable_id,
      payload: { 'stable_id' => stable_id, 'libelle' => 'Nom simplifié' })
  end

  describe '#render' do
    subject(:rendered) { render_inline(described_class.new(llm_rule_suggestion: llm_rule_suggestion)) }

    it 'shows the configured title' do
      expect(rendered.css('h2').text).to include(LLM::ImproveLabelItemComponent.step_title)
    end

    it 'renders the shared summary' do
      expect(rendered.text).to include(LLM::ImproveLabelItemComponent.step_summary)
    end
  end
end
