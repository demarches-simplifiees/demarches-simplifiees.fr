require 'rails_helper'
include ActiveJob::TestHelper

RSpec.describe ApplicationJob, type: :job, skip: true do
  describe 'perform' do
    it do
      expect(Rails.logger).to receive(:info).with(/.+started at.+/)
      expect(Rails.logger).to receive(:info).with(/.+ended at.+/)
      perform_enqueued_jobs { ChildJob.perform_later }
    end
  end

  class ChildJob < ApplicationJob
    def perform; end
  end
end
