# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLM::GenerateRuleSuggestionJob, type: :job do
  let!(:procedure) { create(:procedure, :published) }
  let(:suggestion) { create(:llm_rule_suggestion, :queued, procedure_revision: procedure.published_revision, schema_hash: 'cafebabe') }

  subject { described_class.perform_now(suggestion) }

  it 'transitions queued -> completed when the service succeeds' do
    allow_any_instance_of(LLM::LabelImprover).to receive(:generate_for).and_return([])

    expect { subject }.to change { suggestion.reload.state }.from('queued').to('completed')
  end

  it 'persists returned items and marks completed' do
    items = [
      { op_kind: 'update', stable_id: 1, payload: { 'stable_id' => 1, 'libelle' => 'Libellé 1' }, safety: 'safe' },
      { op_kind: 'update', stable_id: 2, payload: { 'stable_id' => 2, 'libelle' => 'Libellé 2' }, safety: 'safe' }
    ]
    service = instance_double(LLM::LabelImprover, generate_for: items)
    allow(LLM::LabelImprover).to receive(:new).and_return(service)

    subject

    expect(suggestion.reload.state).to eq('completed')
    expect(suggestion.llm_rule_suggestion_items.count).to eq(2)
    expect(suggestion.llm_rule_suggestion_items.order(:stable_id).pluck(:stable_id, :payload)).to eq([
      [1, { 'stable_id' => 1, 'libelle' => 'Libellé 1' }],
      [2, { 'stable_id' => 2, 'libelle' => 'Libellé 2' }]
    ])
  end

  it 'marks the suggestion as failed when the service raises' do
    service = instance_double(LLM::LabelImprover)
    allow(LLM::LabelImprover).to receive(:new).and_return(service)
    allow(service).to receive(:generate_for).and_raise(StandardError.new('Test error'))

    expect { subject }.not_to raise_error
    expect(suggestion.reload.state).to eq('failed')
  end
end
