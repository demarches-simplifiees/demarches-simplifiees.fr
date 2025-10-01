# frozen_string_literal: true

describe LLM::ImproveProcedureJob, type: :job do
  subject(:perform) { described_class.perform_now(procedure) }

  let(:procedure) { create(:procedure, :published) }

  before { Flipper.enable_actor(:llm_nightly_improve_procedure, procedure) }

  it 'creates suggestions and enqueues generation jobs for available rules' do
    expect { perform }.to change { LLMRuleSuggestion.count }.by(2)

    expect(LLM::GenerateRuleSuggestionJob).to have_been_enqueued.exactly(:twice)
  end

  it 'does not duplicate suggestions when run twice' do
    perform
    clear_enqueued_jobs

    expect { perform }.not_to change { LLMRuleSuggestion.count }
    expect(LLM::GenerateRuleSuggestionJob).not_to have_been_enqueued
  end
end
