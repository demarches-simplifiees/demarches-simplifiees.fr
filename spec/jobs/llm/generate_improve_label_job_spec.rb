# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLM::GenerateImproveLabelJob, type: :job do
  let!(:procedure) { create(:procedure, :published) }

  subject { described_class.perform_now(suggestion) }

  context 'with suggestion' do
    let(:suggestion) { create(:llm_rule_suggestion, :queued, procedure_revision: procedure.published_revision, schema_hash: 'cafebabe') }

    it 'transitions queued -> running -> completed when enabled' do
      expect { subject }.to change { suggestion.reload.state }.from('queued').to('completed')
    end

    it 'persists generated items and completes' do
      items = [
        { op_kind: 'update', stable_id: 1, payload: { 'stable_id' => 1, 'libelle' => 'Libellé 1' }, safety: 'safe' },
        { op_kind: 'update', stable_id: 2, payload: { 'stable_id' => 2, 'libelle' => 'Libellé 2' }, safety: 'safe' }
      ]
      service = instance_double(LLM::LabelImprover, generate_for: items, tool_name: LLM::LabelImprover::TOOL_NAME)
      allow(LLM::LabelImprover).to receive(:new).and_return(service)

      subject

      expect(suggestion.reload.state).to eq("completed")
      expect(suggestion.llm_rule_suggestion_items.count).to eq(2)
      expect(suggestion.llm_rule_suggestion_items.order(:stable_id).pluck(:stable_id, :payload)).to eq([
        [1, { 'stable_id' => 1, 'libelle' => 'Libellé 1' }],
        [2, { 'stable_id' => 2, 'libelle' => 'Libellé 2' }]
      ])
    end

    it 'handles exceptions gracefully and updates state to error' do
      service = instance_double(LLM::LabelImprover, tool_name: LLM::LabelImprover::TOOL_NAME)
      allow(LLM::LabelImprover).to receive(:new).and_return(service)
      allow(service).to receive(:generate_for).and_raise(StandardError.new("Test error"))

      expect { subject }.not_to have_enqueued_job(LLM::GenerateImproveLabelJob)

      expect(suggestion.reload.state).to eq('failed')
    end
  end
end
