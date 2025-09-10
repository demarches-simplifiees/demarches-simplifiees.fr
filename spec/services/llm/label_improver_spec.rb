# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLM::LabelImprover do
  let(:schema) do
    [
      { 'stable_id' => 1, 'type' => 'text', 'libelle' => 'LIBELLE 1' },
      { 'stable_id' => 2, 'type' => 'text', 'libelle' => 'Ancien libellé' },
      { 'stable_id' => 3, 'type' => 'text', 'libelle' => 'Titre' },
    ]
  end

  let(:revision) { double('revision', schema_to_llm: schema) }
  let(:suggestion) { double('suggestion', procedure_revision: revision, rule: LLMRuleSuggestion.rules.fetch(:improve_label)) }

  describe '#generate_for' do
    it 'aggregates tool calls into normalized items (no dedup, ignore unrelated tools)' do
      calls = [
        { name: 'improve_label', arguments: { 'update' => { 'stable_id' => 1, 'libelle' => 'Libellé 1' }, 'justification' => 'clarity' } },
        { name: 'improve_label', arguments: { 'update' => { 'stable_id' => 2, 'libelle' => 'Libellé amélioré' } } },
        # unrelated tool must be ignored
        { name: 'other_tool', arguments: { 'x' => 1 } },
      ]

      runner = double()
      allow(runner).to receive(:call).with(anything).and_return(calls)
      service = described_class.new(runner: runner)

      items = service.generate_for(revision)

      expect(items.size).to eq(2)
      payloads = items.map { |i| i[:payload] }
      expect(payloads).to include({ 'stable_id' => 1, 'libelle' => 'Libellé 1' })
      expect(payloads).to include({ 'stable_id' => 2, 'libelle' => 'Libellé amélioré' })

      expect(items.first).to include(op_kind: 'update', safety: 'safe')
      expect(items.find { |i| i[:stable_id] == 1 }[:justification]).to eq('clarity')
    end
  end
end
