# frozen_string_literal: true

describe LLM::ImproveLabelComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(changes:, revision:) }
  let(:changes) { { 'update' => [suggestion_item] } }

  let(:procedure) do
    create(:procedure, types_de_champ_public: [{ type: :text, libelle: 'Ancien libellé', stable_id: 12_345 }])
  end
  let(:revision) { procedure.draft_revision }
  let(:stable_id) { revision.types_de_champ_public.first.stable_id }

  let(:suggestion_item) do
    build(:llm_rule_suggestion_item,
      stable_id:,
      payload: { 'libelle' => 'Nouveau libellé' },
      justification: 'Texte plus simple',
      confidence: 0.9)
  end

  it 'renders the rule explanation callout' do
    expect(rendered.to_html).to include('À quoi sert cette règle ?')
    expect(rendered.to_html).to include('mise à jour des libellés')
  end

  it 'displays the suggested label change' do
    expected_checkbox_id = "selected_update_#{stable_id}"
    expect(rendered.css("##{expected_checkbox_id}").first['value']).to eq(stable_id.to_s)
    expect(rendered.to_html).to include('Ancien libellé')
    expect(rendered.to_html).to include('→ Nouveau libellé')
    expect(rendered.to_html).to include('Texte plus simple')
    expect(rendered.to_html).to include('confiance: 0.9')
  end

  it 'embeds the serialized payload in the hidden field' do
    hidden_field = rendered.css("input[name='changes_json']").first
    payload = JSON.parse(hidden_field['value'])

    expect(payload).to eq(
      'update' => [
        {
          'stable_id' => stable_id,
          'libelle' => 'Nouveau libellé',
          'justification' => 'Texte plus simple',
          'confidence' => 0.9
        }
      ]
    )
  end
end
