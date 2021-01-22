include ActiveJob::TestHelper

RSpec.describe ApiEntreprise::Job, type: :job do
  # https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on
  context 'when an exception is raised' do
    subject do
      assert_performed_jobs(try) do
        ExceptionJob.perform_later(error) rescue StandardError
      end
    end

    context 'when it is a service_unavaible' do
      let(:error) { :standard_error }
      let(:try) { 1 }

      it { subject }
    end

    context 'when it is a service_unavaible' do
      let(:error) { :service_unavaible }
      let(:try) { 5 }

      it { subject }
    end

    context 'when it is a bad gateway' do
      let(:error) { :bad_gateway }
      let(:try) { 5 }

      it { subject }
    end
  end

  class ExceptionJob < ApiEntreprise::Job
    def perform(exception)
      case exception
      when :service_unavaible
        raise ApiEntreprise::API::ServiceUnavailable
      when :bad_gateway
        raise ApiEntreprise::API::BadGateway
      else
        raise StandardError
      end
    end
  end
end
