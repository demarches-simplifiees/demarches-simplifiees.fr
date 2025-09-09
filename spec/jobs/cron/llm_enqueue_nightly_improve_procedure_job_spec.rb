# frozen_string_literal: true

describe Cron::LLMEnqueueNightlyImproveProcedureJob, type: :job do
  subject { described_class.perform_now }

  let!(:p1) { create(:procedure, :published) }
  let!(:p2) { create(:procedure, :published) }

  before { Flipper.enable_actor(:llm_nightly_improve_procedure, p1) }

  describe 'perform' do
    it 'enqueues jobs only for procedures with feature enabled' do
      expect { subject }.to have_enqueued_job(LLM::GenerateImproveLabelJob).with(an_instance_of(LLMRuleSuggestion)).once
    end

    context 'idempotence' do
      it 'create once' do
        expect { subject }.to change { LLMRuleSuggestion.count }.by(1)
        expect { subject }.not_to change { LLMRuleSuggestion.count }
      end
    end
  end
end
