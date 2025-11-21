# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLM::StructureImprover do
  let(:schema) do
    [
      { 'stable_id' => 1, 'type' => 'header_section', 'libelle' => 'Informations générales' },
      { 'stable_id' => 2, 'type' => 'text', 'libelle' => 'Nom' },
      { 'stable_id' => 3, 'type' => 'text', 'libelle' => 'Adresse' },
    ]
  end
  let(:rule) { LLMRuleSuggestion.rules.fetch('improve_structure') }
  let(:revision) { double('revision', schema_to_llm: schema) }
  let(:suggestion) { double('suggestion', procedure_revision: revision, rule:) }

  describe '#generate_for' do
    it 'normalises tool calls into structured items' do
      calls = [
        {
          name: rule,
          arguments: {
            'update' => { 'stable_id' => 2, 'position' => 3, 'mandatory' => false },
            'justification' => 'Regrouper sous la section',
            'confidence' => 0.8,
          },
        },
        {
          name: rule,
          arguments: {
            'add' => { 'libelle' => 'Nouvelle section', "after_stable_id" => 1 },
            'justification' => 'Clarifier le parcours',
            'confidence' => 0.6,
          },
        },
        { name: 'other_tool', arguments: { 'x' => 1 } },
      ]
      runner = double()
      allow(runner).to receive(:call).with(anything).and_return(calls)
      service = described_class.new(runner:)

      items = service.generate_for(suggestion)

      expect(items.size).to eq(2)
      expect(items.first).to include(op_kind: 'update', stable_id: 2)
      expect(items.first[:payload]).to include('position' => 3, 'mandatory' => false)
      expect(items.second).to include(op_kind: 'add')
      expect(items.second[:payload]).to include('libelle' => 'Nouvelle section', 'after_stable_id' => 1)
    end
  end
end
