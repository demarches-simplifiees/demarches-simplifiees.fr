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
  let(:usage) { double() }
  let(:procedure_context) do
    {
      libelle: 'Test Procedure',
      description: 'Test description',
      for_individual: false,
      champs_entree: '- SIRET de l\'ENTREPRISE (fournit automatiquement ~20 informations : raison sociale, adresse, forme juridique, NAF, etc.)'
    }
  end
  let(:revision) { double('revision', schema_to_llm: schema, procedure_id: 123, procedure_context_to_llm: procedure_context) }
  let(:suggestion) { double('suggestion', procedure_revision: revision, rule: LLMRuleSuggestion.rules.fetch(:improve_label)) }
  before do
    allow(usage).to receive(:with_indifferent_access).and_return({
      prompt_tokens: 100,
      completion_tokens: 200,
      total_tokens: 300,
    }.with_indifferent_access)
  end
  describe '#generate_for' do
    it 'aggregates tool calls into normalized items (no dedup, ignore unrelated tools)' do
      tool_calls = [
        { name: 'improve_label', arguments: { 'update' => { 'stable_id' => 1, 'libelle' => 'Libellé 1', 'description' => 'bim', 'position' => 1 }, 'justification' => 'clarity' } },
        { name: 'improve_label', arguments: { 'update' => { 'stable_id' => 2, 'libelle' => 'Libellé amélioré', 'description' => 'bam', 'position' => 2 } } },
        # unrelated tool must be ignored
        { name: 'other_tool', arguments: { 'x' => 1 } },
      ]

      runner = double()
      allow(runner).to receive(:call).with(anything).and_return([tool_calls, usage])
      service = described_class.new(runner: runner)
      tool_calls, token_usage = service.generate_for(suggestion)

      expect(tool_calls.size).to eq(2)
      payloads = tool_calls.map { |i| i[:payload] }
      expect(payloads).to include({ 'stable_id' => 1, 'libelle' => 'Libellé 1', 'description' => 'bim', 'position' => 1 })
      expect(payloads).to include({ 'stable_id' => 2, 'libelle' => 'Libellé amélioré', 'description' => 'bam', 'position' => 2 })

      expect(tool_calls.first).to include(op_kind: 'update')
      expect(tool_calls.find { |i| i[:stable_id] == 1 }[:justification]).to eq('clarity')
    end
  end

  describe '#sanitize_schema_for_prompt' do
    it 'removes dangerous characters from libelle and description fields' do
      dangerous_schema = [
        { 'stable_id' => 1, 'libelle' => 'Test<script>alert("xss")</script>', 'description' => 'Desc with {brackets} and [arrays]' },
        { 'stable_id' => 2, 'libelle' => 'Normal text', 'description' => nil },
        { 'stable_id' => 3, 'libelle' => 'Text with control chars: ' + "\x00\x01\x1F", 'description' => 'Valid desc' },
      ]

      service = described_class.new
      result = service.send(:sanitize_schema_for_prompt, dangerous_schema)

      expect(result[0]['libelle']).to eq('Testscriptalert("xss")/script')
      expect(result[0]['description']).to eq('Desc with brackets and arrays')
      expect(result[1]['libelle']).to eq('Normal text')
      expect(result[1]['description']).to be_nil
      expect(result[2]['libelle']).to eq('Text with control chars:')
      expect(result[2]['description']).to eq('Valid desc')
    end

    it 'sanitizes choices arrays' do
      schema_with_choices = [
        { 'stable_id' => 1, 'choices' => ['Option <b>1</b>', 'Option {2}', 'Normal option'] },
      ]

      service = described_class.new
      result = service.send(:sanitize_schema_for_prompt, schema_with_choices)
      expect(result[0]['choices']).to eq(['Option b1/b', 'Option 2', 'Normal option'])
    end

    it 'preserves non-string fields unchanged' do
      schema = [
        { 'stable_id' => 123, 'type' => 'text', 'mandatory' => true, 'position' => 1 },
      ]

      service = described_class.new
      result = service.send(:sanitize_schema_for_prompt, schema)

      expect(result[0]['stable_id']).to eq(123)
      expect(result[0]['type']).to eq('text')
      expect(result[0]['mandatory']).to eq(true)
      expect(result[0]['position']).to eq(1)
    end

    it 'returns schema unchanged if not an array' do
      service = described_class.new
      expect(service.send(:sanitize_schema_for_prompt, 'not an array')).to eq('not an array')
      expect(service.send(:sanitize_schema_for_prompt, {})).to eq({})
    end
  end

  describe '#filter_invalid_llm_result' do
    it 'returns true for invalid results' do
      service = described_class.new

      # Invalid: stable_id is nil
      expect(service.send(:filter_invalid_llm_result, nil, 'libelle', 'description')).to be true

      # Invalid: libelle is blank
      expect(service.send(:filter_invalid_llm_result, 123, '', 'description')).to be true
      expect(service.send(:filter_invalid_llm_result, 123, nil, 'description')).to be true
      expect(service.send(:filter_invalid_llm_result, 123, '   ', 'description')).to be true
    end

    it 'returns false for valid results' do
      service = described_class.new

      expect(service.send(:filter_invalid_llm_result, 123, 'valid libelle', 'valid description')).to be false
      expect(service.send(:filter_invalid_llm_result, 123, 'libelle', '')).to be false # description can be empty
    end
  end
end
