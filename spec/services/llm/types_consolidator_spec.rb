# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLM::TypesConsolidator do
  let(:schema) do
    [
      { 'stable_id' => 1, 'type' => 'text', 'libelle' => 'Adresse email du contact' },
      { 'stable_id' => 2, 'type' => 'text', 'libelle' => 'Numéro de téléphone' },
      { 'stable_id' => 3, 'type' => 'text', 'libelle' => 'Adresse postale' },
      { 'stable_id' => 4, 'type' => 'communes', 'libelle' => 'Commune' },
    ]
  end
  let(:rule) { 'consolidate_types' }
  let(:usage) { double() }
  let(:procedure_context) do
    {
      libelle: 'Test Procedure',
      description: 'Test description',
      for_individual: false,
      champs_entree: '- SIRET de l\'ENTREPRISE (fournit automatiquement ~20 informations : raison sociale, adresse, forme juridique, NAF, etc.)'
    }
  end
  let(:revision) { double('revision', schema_to_llm: schema, procedure_id: 1, procedure_context_to_llm: procedure_context) }
  let(:suggestion) { double('suggestion', procedure_revision: revision, rule:) }

  before do
    allow(usage).to receive(:with_indifferent_access).and_return({
      prompt_tokens: 100,
      completion_tokens: 200,
      total_tokens: 300,
    }.with_indifferent_access)
  end

  describe '#generate_for' do
    it 'normalises update tool calls for type changes' do
      calls = [
        {
          name: rule,
          arguments: {
            'update' => { 'stable_id' => 1, 'type_champ' => 'email' },
            'justification' => 'Le libellé indique une adresse email',
          },
        },
        {
          name: rule,
          arguments: {
            'update' => { 'stable_id' => 2, 'type_champ' => 'phone' },
            'justification' => 'Le libellé indique un numéro de téléphone',
          },
        },
      ]

      runner = double()
      allow(runner).to receive(:call).with(anything).and_return([calls, usage])
      service = described_class.new(runner:)

      tool_calls, _token_usage = service.generate_for(suggestion)

      expect(tool_calls.size).to eq(2)
      expect(tool_calls.first).to include(op_kind: 'update', stable_id: 1)
      expect(tool_calls.first[:payload]).to include('type_champ' => 'email')
      expect(tool_calls.second).to include(op_kind: 'update', stable_id: 2)
      expect(tool_calls.second[:payload]).to include('type_champ' => 'phone')
    end

    it 'normalises destroy tool calls for redundant fields' do
      calls = [
        {
          name: rule,
          arguments: {
            'update' => { 'stable_id' => 3, 'type_champ' => 'address' },
            'justification' => 'Utiliser le type address pour auto-complétion',
          },
        },
        {
          name: rule,
          arguments: {
            'destroy' => { 'stable_id' => 4 },
            'justification' => 'Le champ commune devient redondant avec address',
          },
        },
      ]

      runner = double()
      allow(runner).to receive(:call).with(anything).and_return([calls, usage])
      service = described_class.new(runner:)

      tool_calls, _token_usage = service.generate_for(suggestion)

      expect(tool_calls.size).to eq(2)
      expect(tool_calls.first).to include(op_kind: 'update', stable_id: 3)
      expect(tool_calls.first[:payload]).to include('type_champ' => 'address')
      expect(tool_calls.second).to include(op_kind: 'destroy', stable_id: 4)
    end

    it 'filters invalid type_champ values' do
      calls = [
        {
          name: rule,
          arguments: {
            'update' => { 'stable_id' => 1, 'type_champ' => 'invalid_type' },
            'justification' => 'Test',
          },
        },
      ]

      runner = double()
      allow(runner).to receive(:call).with(anything).and_return([calls, usage])
      service = described_class.new(runner:)

      tool_calls, _token_usage = service.generate_for(suggestion)

      expect(tool_calls).to be_empty
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

  describe 'TOOL_DEFINITION' do
    it 'has the correct tool name' do
      expect(described_class::TOOL_DEFINITION.dig(:function, :name)).to eq('consolidate_types')
    end

    it 'defines update and destroy operations' do
      properties = described_class::TOOL_DEFINITION.dig(:function, :parameters, :properties)
      expect(properties).to have_key(:update)
      expect(properties).to have_key(:destroy)
      expect(properties).to have_key(:justification)
    end
  end
end
