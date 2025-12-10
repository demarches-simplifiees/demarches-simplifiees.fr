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
  let(:usage) { double() }
  let(:procedure_context) do
    {
      libelle: 'Test Procedure',
      description: 'Test description',
      for_individual: false,
      champs_entree: '- SIRET de l\'ENTREPRISE (fournit automatiquement ~20 informations : raison sociale, adresse, forme juridique, NAF, etc.)'
    }
  end
  let(:revision) { double('revision', schema_to_llm: schema, procedure_id: 1, procedure_context_to_llm: procedure_context, types_de_champ: []) }
  let(:suggestion) { double('suggestion', procedure_revision: revision, rule:) }
  before do
   allow(usage).to receive(:with_indifferent_access).and_return({
     prompt_tokens: 100,
     completion_tokens: 200,
     total_tokens: 300,
   }.with_indifferent_access)
 end
  describe '#generate_for' do
    it 'normalises tool calls into structured items' do
      calls = [
        {
          name: rule,
          arguments: {
            'update' => { 'stable_id' => 2, 'position' => 3, 'mandatory' => false },
            'justification' => 'Regrouper sous la section',
          },
        },
        {
          name: rule,
          arguments: {
            'add' => { 'libelle' => 'Nouvelle section', "after_stable_id" => 1 },
            'justification' => 'Clarifier le parcours',
          },
        },
        { name: 'other_tool', arguments: { 'x' => 1 } },
      ]
      runner = double()
      allow(runner).to receive(:call).with(anything).and_return([calls, usage])
      service = described_class.new(runner:)

      tool_calls, token_usage = service.generate_for(suggestion)

      expect(tool_calls.size).to eq(2)
      expect(tool_calls.first).to include(op_kind: 'update', stable_id: 2)
      expect(tool_calls.first[:payload]).to include('position' => 3, 'mandatory' => false)
      expect(tool_calls.second).to include(op_kind: 'add')
      expect(tool_calls.second[:payload]).to include('libelle' => 'Nouvelle section', 'after_stable_id' => 1)
    end
  end
end
