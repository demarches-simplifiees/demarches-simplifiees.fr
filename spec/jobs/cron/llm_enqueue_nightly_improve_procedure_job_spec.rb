# frozen_string_literal: true

describe Cron::LLMEnqueueNightlyImproveProcedureJob, type: :job do
  subject { described_class.perform_now }

  let!(:p1) { create(:procedure, :published) }
  let!(:p2) { create(:procedure, :published) }
  let!(:p3) { create(:procedure, :published) }

  before do
    # Enable only for p1 and p3 at procedure scope
    Flipper.enable_actor(:llm_nightly_improve_procedure, p1)
    Flipper.enable_actor(:llm_nightly_improve_procedure, p3)
  end
  describe 'perform' do
    it 'enqueues jobs only for procedures with feature enabled' do
      expect { subject }.to have_enqueued_job(LLM::GenerateImproveLabelJob).with(p1.id).with(p3.id)
    end
  end
end
