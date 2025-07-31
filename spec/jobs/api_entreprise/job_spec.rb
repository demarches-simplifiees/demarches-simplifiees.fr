# frozen_string_literal: true

include ActiveJob::TestHelper

RSpec.describe APIEntreprise::Job, type: :job do
  # https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html
  # #method-i-retry_on
  describe '#perform' do
    let(:dossier) { create(:dossier, :with_entreprise) }

    context 'when an un-retriable error is raised' do
      let(:errors) { [:standard_error] }

      it 'does not retry' do
        ensure_errors_force_n_retry(errors, 1)
      end
    end

    context 'when a retriable error is raised' do
      let(:errors) { [:service_unavailable, :bad_gateway, :timed_out] }

      it 'retries 5 times' do
        ensure_errors_force_n_retry(errors, 5)
        expect(dossier.reload.api_entreprise_job_exceptions.first).to match('APIEntreprise::API::Error::ServiceUnavailable')
      end
    end

    context 'when error with an etablissement on a champ' do
      let(:types_de_champ_public) do
        [{ type: :siret }]
      end

      let(:procedure) { create(:procedure, types_de_champ_public:) }
      let(:dossier) { create(:dossier, procedure:) }

      it "retries 5 times" do
        champ = dossier.champs.first
        etablissement = create(:etablissement, champ:)

        assert_performed_jobs(5) do
          ErrorJob.perform_later(:service_unavailable, etablissement)
        end
      end
    end

    def ensure_errors_force_n_retry(errors, retry_nb)
      etablissement = dossier.etablissement

      errors.each do |error|
        assert_performed_jobs(retry_nb) do
          ErrorJob.perform_later(error, etablissement) rescue StandardError
        end
      end
    end
  end

  class ErrorJob < APIEntreprise::Job
    def perform(error, etablissement)
      @etablissement = etablissement

      response = Typhoeus::Response.new(
        effective_url: 'http://host.com/path',
        code: '666',
        body: 'body',
        return_message: 'return_message',
        total_time: 10,
        connect_time: 20,
        headers: 'headers'
      )

      case error
      when :service_unavailable
        raise APIEntreprise::API::Error::ServiceUnavailable.new(response)
      when :bad_gateway
        raise APIEntreprise::API::Error::BadGateway.new(response)
      when :timed_out
        raise APIEntreprise::API::Error::TimedOut.new(response)
      else
        raise StandardError
      end
    end
  end
end
