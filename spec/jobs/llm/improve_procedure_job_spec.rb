# frozen_string_literal: true

describe LLM::ImproveProcedureJob, type: :job do
  subject(:perform) { described_class.perform_now(procedure, rules) }
  let(:rules) { LLMRuleSuggestion.rules.values }
  let(:procedure) { create(:procedure, :published) }

  before { Flipper.enable_actor(:llm_nightly_improve_procedure, procedure) }

  it 'creates suggestions and enqueues generation jobs for available rules on the draft revision' do
    expect { perform }.to change { LLMRuleSuggestion.count }.by(2)

    expect(LLM::GenerateRuleSuggestionJob).to have_been_enqueued.exactly(:twice)
    expect(LLMRuleSuggestion.distinct.pluck(:procedure_revision_id)).to contain_exactly(procedure.draft_revision.id)
  end

  it 'does not duplicate suggestions when run twice' do
    perform
    clear_enqueued_jobs

    expect { perform }.not_to change { LLMRuleSuggestion.count }
    expect(LLM::GenerateRuleSuggestionJob).not_to have_been_enqueued
  end

  it 'requeues failed suggestions' do
    perform
    LLMRuleSuggestion.update_all(state: :failed)
    clear_enqueued_jobs

    described_class.perform_now(procedure, rules)

    expect(LLMRuleSuggestion.pluck(:state)).to all(eq('queued'))
    expect(LLM::GenerateRuleSuggestionJob).to have_been_enqueued.exactly(:twice)
  end
end
