# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLM::CleanerImprover do
  let(:schema) do
    [
      { 'stable_id' => 1, 'type' => 'address', 'libelle' => 'Adresse postale' },
      { 'stable_id' => 2, 'type' => 'text', 'libelle' => 'Commune' },
      { 'stable_id' => 3, 'type' => 'text', 'libelle' => 'Code postal' },
    ]
  end
  let(:rule) { 'cleaner' }
  let(:usage) { double() }
  let(:procedure) { double('procedure', libelle: 'Test Procedure', description: 'Test description', for_individual: false) }
  let(:types_de_champ) do
    [
      double('tdc1', stable_id: 1, type_champ: 'address'),
      double('tdc2', stable_id: 2, type_champ: 'text'),
      double('tdc3', stable_id: 3, type_champ: 'text'),
    ]
  end
  let(:revision) { double('revision', schema_to_llm: schema, procedure_id: 1, types_de_champ:, procedure:) }
  let(:suggestion) { double('suggestion', procedure_revision: revision, rule:) }

  before do
    allow(usage).to receive(:with_indifferent_access).and_return({
      prompt_tokens: 100,
      completion_tokens: 200,
      total_tokens: 300,
    }.with_indifferent_access)
  end

  describe '#generate_for' do
    it 'normalises destroy tool calls for redundant fields' do
      calls = [
        {
          name: rule,
          arguments: {
            'destroy' => { 'stable_id' => 2 },
            'justification' => 'Le champ adresse fournit déjà la commune',
          },
        },
        {
          name: rule,
          arguments: {
            'destroy' => { 'stable_id' => 3 },
            'justification' => 'Le champ adresse fournit déjà le code postal',
          },
        },
      ]

      runner = double()
      allow(runner).to receive(:call).with(anything).and_return([calls, usage])
      service = described_class.new(runner:)

      tool_calls, _token_usage = service.generate_for(suggestion)

      expect(tool_calls.size).to eq(2)
      expect(tool_calls.first).to include(op_kind: 'destroy', stable_id: 2)
      expect(tool_calls.second).to include(op_kind: 'destroy', stable_id: 3)
    end

    it 'ignores unrelated tool calls' do
      calls = [
        { name: 'other_tool', arguments: { 'x' => 1 } },
      ]

      runner = double()
      allow(runner).to receive(:call).with(anything).and_return([calls, usage])
      service = described_class.new(runner:)

      tool_calls, _token_usage = service.generate_for(suggestion)

      expect(tool_calls).to be_empty
    end
  end
end
