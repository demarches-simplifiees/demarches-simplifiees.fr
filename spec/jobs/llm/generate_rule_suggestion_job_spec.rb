# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLM::GenerateRuleSuggestionJob, type: :job do
  let!(:procedure) { create(:procedure, :published) }
  let(:suggestion) { create(:llm_rule_suggestion, :queued, procedure_revision: procedure.published_revision, schema_hash: 'cafebabe') }
  let(:token_usage) do
    {
      prompt_tokens: 1234,
      completion_tokens: 4321,
      total_tokens: 5432,
    }
  end
  subject { described_class.perform_now(suggestion, action: "nightly") }

  it 'transitions queued -> completed when the service succeeds' do
    allow_any_instance_of(LLM::LabelImprover).to receive(:generate_for).and_return([[], token_usage])
    expect { subject }.to change { suggestion.reload.state }.from('queued').to('completed')
  end

  it 'persists returned items and marks completed' do
    items = [
      { op_kind: 'update', stable_id: 1, payload: { 'stable_id' => 1, 'libelle' => 'Libellé 1' } },
      { op_kind: 'update', stable_id: 2, payload: { 'stable_id' => 2, 'libelle' => 'Libellé 2' } },
    ]

    service = instance_double(LLM::LabelImprover, generate_for: [items, token_usage])
    allow(LLM::LabelImprover).to receive(:new).and_return(service)

    subject
    expect(suggestion.error).to be_nil
    expect(suggestion.reload.state).to eq('completed')
    expect(suggestion.llm_rule_suggestion_items.count).to eq(2)
    expect(suggestion.llm_rule_suggestion_items.order(:stable_id).pluck(:stable_id, :payload)).to eq([
      [1, { 'stable_id' => 1, 'libelle' => 'Libellé 1' }],
      [2, { 'stable_id' => 2, 'libelle' => 'Libellé 2' }],
    ])
    expect(suggestion.token_usage.with_indifferent_access).to eq(token_usage.merge("estimated_cost_eur" => 0.0383319).with_indifferent_access)
  end

  it 'marks the suggestion as failed when the service raises' do
    service = instance_double(LLM::LabelImprover)
    allow(LLM::LabelImprover).to receive(:new).and_return(service)
    allow(service).to receive(:generate_for).and_raise(StandardError.new('Test error'))

    expect { subject }.not_to raise_error
    expect(suggestion.reload.state).to eq('failed')
  end
end
