# frozen_string_literal: true

describe Cron::LLMEnqueueNightlyImproveProcedureJob, type: :job do
  subject(:perform) { described_class.perform_now }

  let!(:p1) { create(:procedure, :published) }
  let!(:p2) { create(:procedure, :published) }

  before { Flipper.enable_actor(:llm_nightly_improve_procedure, p1) }

  it 'enqueues the dedicated job only for procedures with feature enabled' do
    perform

    expect(LLM::ImproveProcedureJob).to have_been_enqueued.with(p1, [LLMRuleSuggestion.rules.fetch(:improve_label)])
    expect(LLM::ImproveProcedureJob).not_to have_been_enqueued.with(p2, [LLMRuleSuggestion.rules.fetch(:improve_label)])
  end
end
