# frozen_string_literal: true

describe LLM::ImproveLabelComponent, type: :component do
  subject(:rendered) { render_inline(component) }
  let(:component) { described_class.new(suggestion: llm_rule_suggestion) }

  let(:procedure) do
    create(:procedure, types_de_champ_public: [{ type: :text, libelle: 'Ancien libellé', stable_id: 12_345 }])
  end
  let(:revision) { procedure.draft_revision }
  let(:schema_hash) { Digest::SHA256.hexdigest(revision.schema_to_llm.to_json) }
  let(:llm_rule_suggestion) { create(:llm_rule_suggestion, procedure_revision: revision, schema_hash:, rule: LLM::LabelImprover::TOOL_NAME) }
  let!(:suggestion_item) do
    create(:llm_rule_suggestion_item,
      llm_rule_suggestion: llm_rule_suggestion,
      stable_id: 12_345,
      payload: { 'libelle' => 'Nouveau libellé' },
      justification: 'Texte plus simple',
      confidence: 0.9)
  end

  it 'renders the rule explanation callout' do
    expect(rendered.to_html).to include('À quoi sert cette règle ?')
    expect(rendered.to_html).to include('mise à jour des libellés')
  end

  it 'displays the suggested label change' do
    expect(rendered.to_html).to include('Ancien libellé')
    expect(rendered.to_html).to include('→ Nouveau libellé')
    expect(rendered.to_html).to include('Texte plus simple')
    expect(rendered.to_html).to include('confiance: 0.9')
  end
end
