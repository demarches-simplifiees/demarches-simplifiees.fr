# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLM::StructureImprover do
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:types_de_champ_public) do
    [
      { type: :text, stable_id: 1, libelle: 'nom' },
      { type: :text, stable_id: 2, libelle: 'prenom' },
      { type: :explication, stable_id: 3, libelle: 'explication a la fin' },
    ]
  end
  let(:rule) { LLMRuleSuggestion.rules.fetch('improve_structure') }
  let(:usage) { double() }
  let(:suggestion) { create(:llm_rule_suggestion, procedure_revision: procedure.draft_revision, rule:) }

  before do
   allow(usage).to receive(:with_indifferent_access).and_return({
     prompt_tokens: 100,
     completion_tokens: 200,
     total_tokens: 300,
   }.with_indifferent_access)
 end
  describe '#generate_for' do
    let(:runner) { double() }
    let(:service) { described_class.new(runner:) }
    let(:calls) { [{ name: rule, arguments: arguments }, { name: 'other_tool', arguments: { 'x' => 1 } }] }
    let(:tool_calls) do
      allow(runner).to receive(:call).with(anything).and_return([calls, usage])
      service.generate_for(suggestion).first
    end

    before do
      allow(runner).to receive(:call).with(anything).and_return([calls, usage])
    end

    context 'add_section_at_start' do
      let(:arguments) do
        {
          'add' => {
            'generated_stable_id' => -1,
            'libelle' => 'Nouveau titre de section',
            'header_section_level' => 1,
            'parent_id' => nil,
            'after_stable_id' => nil,
          },
        }
      end

      it 'creates an add item with correct payload' do
        expect(tool_calls.first).to include(op_kind: 'add', stable_id: nil, verify_status: 'review', justification: nil)
        expect(tool_calls.first[:payload]).to eq(arguments['add'].compact.merge('type_champ' => 'header_section'))
      end

      it 'returns 1 tool call' do
        expect(tool_calls.size).to eq(1)
      end
    end

    context 'move_field_under_new_section' do
      let(:arguments) do
        {
          'update' => {
            'stable_id' => 1,
            'after_stable_id' => -1,
            'parent_id' => nil,
          },
        }
      end

      it 'creates an update item with correct payload' do
        expect(tool_calls.first).to include(op_kind: 'update', stable_id: 1, verify_status: 'review', justification: nil)
        expect(tool_calls.first[:payload]).to eq(arguments['update'].compact)
      end

      it 'returns 1 tool call' do
        expect(tool_calls.size).to eq(1)
      end
    end

    context 'add_section_after_field' do
      let(:arguments) do
        {
          'add' => {
            'generated_stable_id' => -2,
            'after_stable_id' => 1,
            'libelle' => 'Nouveau titre de section',
            'header_section_level' => 1,
            'parent_id' => nil,
          },
        }
      end

      it 'creates an add item with correct payload' do
        expect(tool_calls.first).to include(op_kind: 'add', stable_id: nil, verify_status: 'review', justification: nil)
        expect(tool_calls.first[:payload]).to eq(arguments['add'].compact.merge('type_champ' => 'header_section'))
      end

      it 'returns 1 tool call' do
        expect(tool_calls.size).to eq(1)
      end
    end

    context 'move_field_under_existing' do
      let(:arguments) do
        {
          'update' => {
            'stable_id' => 3,
            'after_stable_id' => 2,
          },
        }
      end

      it 'creates an update item with correct payload' do
        expect(tool_calls.first).to include(op_kind: 'update', stable_id: 3, verify_status: 'review', justification: nil)
        expect(tool_calls.first[:payload]).to eq(arguments['update'].compact)
      end

      it 'returns 1 tool call' do
        expect(tool_calls.size).to eq(1)
      end
    end

    context 'token usage' do
      let(:arguments) { {} } # dummy, not used

      it 'returns correct token usage' do
        _, token_usage = service.generate_for(suggestion)
        expect(token_usage).to eq(usage.with_indifferent_access)
      end
    end
  end
end
