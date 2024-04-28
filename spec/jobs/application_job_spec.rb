# frozen_string_literal: true

include ActiveJob::TestHelper

RSpec.describe ApplicationJob, type: :job do
  it_behaves_like 'a job retrying transient errors'

  describe 'perform' do
    before do
      allow(Rails.logger).to receive(:info)
    end

    it 'logs start time and end time' do
      perform_enqueued_jobs { ChildJob.perform_later }
      expect(Rails.logger).to have_received(:info).with(/started at/).once
      expect(Rails.logger).to have_received(:info).with(/ended at/).once
    end
  end

  class ChildJob < ApplicationJob
    def perform; end
  end
end
