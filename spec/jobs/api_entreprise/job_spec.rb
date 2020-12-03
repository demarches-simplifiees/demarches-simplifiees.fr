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
      case error
      when :service_unavaible
        raise ApiEntreprise::API::ServiceUnavailable
      when :bad_gateway
        raise ApiEntreprise::API::BadGateway
      when :timed_out
        raise ApiEntreprise::API::TimedOut
      else
        raise StandardError
      end
    end
  end
end
