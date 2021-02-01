include ActiveJob::TestHelper

RSpec.describe ApiEntreprise::Job, type: :job do
  # https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html
  # #method-i-retry_on
  describe '#perform' do
    context 'when a un retryable error is raised' do
      let(:errors) { [:standard_error] }

      it 'does not retry' do
        ensure_errors_force_n_retry(errors, 1)
      end
    end

    context 'when a retryable error is raised' do
      let(:errors) { [:service_unavaible, :bad_gateway, :timed_out] }

      it 'retries 5 times' do
        ensure_errors_force_n_retry(errors, 5)
      end
    end

    def ensure_errors_force_n_retry(errors, retry_nb)
      errors.each do |error|
        assert_performed_jobs(retry_nb) do
          ErrorJob.perform_later(error) rescue StandardError
        end
      end
    end
  end

  class ErrorJob < ApiEntreprise::Job
    def perform(error)
      response = OpenStruct.new(
        effective_url: 'http://host.com/path',
        code: '666',
        body: 'body',
        return_message: 'return_message',
        total_time: 10,
        connect_time: 20,
        headers: 'headers'
      )

      case error
      when :service_unavaible
        raise ApiEntreprise::API::Error::ServiceUnavailable.new(response)
      when :bad_gateway
        raise ApiEntreprise::API::Error::BadGateway.new(response)
      when :timed_out
        raise ApiEntreprise::API::Error::TimedOut.new(response)
      else
        raise StandardError
      end
    end
  end
end
