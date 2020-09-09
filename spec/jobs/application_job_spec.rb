include ActiveJob::TestHelper

RSpec.describe ApplicationJob, type: :job do
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

  context 'when ::Excon::Error::BadRequest is raised' do
    # https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on
    # retry on will try 5 times and then bubble up the error
    it 'makes 5 attempts' do
      assert_performed_jobs 5 do
        ExconErrJob.perform_later rescue ::Excon::Error::BadRequest
      end
    end
  end

  class ChildJob < ApplicationJob
    def perform; end
  end

  class ExconErrJob < ApplicationJob
    def perform
      raise ::Excon::Error::BadRequest.new('bad request')
    end
  end
end
