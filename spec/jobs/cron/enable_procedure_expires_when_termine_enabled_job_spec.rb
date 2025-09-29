# frozen_string_literal: true

require 'rails_helper'

describe Cron::EnableProcedureExpiresWhenTermineEnabledJob, type: :job do
  subject { described_class.perform_now }
  let!(:procedure) { create(:procedure, procedure_expires_when_termine_enabled: false) }
  context 'when env[ENABLE_PROCEDURE_EXPIRES_WHEN_TERMINE_ENABLED_JOB_LIMIT] is present' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ENABLE_PROCEDURE_EXPIRES_WHEN_TERMINE_ENABLED_JOB_LIMIT').and_return(10)
    end

    it 'performs' do
      expect { subject }.to change { procedure.reload.procedure_expires_when_termine_enabled }.from(false).to(true)
    end

    it 'fails gracefuly by catching any error (to prevent re-enqueue and sending too much email)' do
      expect(Procedure).to receive(:where).and_raise(StandardError)
      expect { subject }.not_to raise_error
    end
  end

  context 'when env[ENABLE_PROCEDURE_EXPIRES_WHEN_TERMINE_ENABLED_JOB_LIMIT] is absent' do
    it 'does not perform without limit' do
      expect { subject }.not_to change { procedure.reload.procedure_expires_when_termine_enabled }
    end
  end
end
