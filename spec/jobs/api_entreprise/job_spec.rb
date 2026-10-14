# frozen_string_literal: true

RSpec.describe APIEntreprise::Job, type: :job do
  include ActiveJob::TestHelper
  before do
    [5, 50, 100, 250].each do |pool|
      Kredis.redis.del(APIEntreprise::RateLimiter.remaining_key(pool), APIEntreprise::RateLimiter.reset_key(pool))
    end
  end

  describe '#perform' do
    let(:dossier) { create(:dossier, :with_entreprise) }

    context 'when error with an etablissement on a champ' do
      let(:procedure) { create(:procedure, public_type_de_champs:) }
      let(:public_type_de_champs) { [{ type: :siret }] }
      let(:dossier) { create(:dossier, procedure:) }

      it "re-raises so sidekiq can retry" do
        champ = dossier.champ_data.first
        champ.update!(value: '12345678901234')

        etablissement = create(:etablissement, champ_data: champ)

        expect { ErrorJob.perform_now(etablissement) }
          .to raise_error(StandardError, /API Entreprise error/)

        expect(champ.reload.value).not_to be_nil
      end
    end
  end

  describe 'before_perform checks' do
    let(:pool) { APIEntreprise::API::DEFAULT_POOL }

    before do
      allow(APIEntreprise::HealthChecker).to receive(:provider_up?).and_return(true)
    end

    context 'when provider is up and not throttled' do
      before { allow(APIEntreprise::RateLimiter).to receive(:throttled?).with(pool).and_return(false) }

      it 'runs the job normally' do
        dossier = create(:dossier, :with_entreprise)
        etablissement = dossier.etablissement

        expect { ErrorJob.perform_now(etablissement) }.to raise_error(StandardError, /API Entreprise error/)
      end
    end

    context 'when provider is down' do
      let(:ping_key) { 'insee/sirene' }

      before do
        allow_any_instance_of(ErrorJob).to receive(:ping_key_for_job).and_return(ping_key)
        allow(APIEntreprise::HealthChecker).to receive(:provider_up?).with(ping_key).and_return(false)
      end

      it 'raises ProviderDownError without checking rate limit' do
        dossier = create(:dossier, :with_entreprise)
        etablissement = dossier.etablissement

        expect(APIEntreprise::RateLimiter).not_to receive(:throttled?)
        expect { ErrorJob.perform_now(etablissement) }
          .to raise_error(APIEntreprise::Job::ProviderDownError, /provider #{ping_key} is down/)
      end
    end

    context 'when provider is up but throttled' do
      before do
        allow(APIEntreprise::RateLimiter).to receive(:throttled?).with(pool).and_return(true)
      end

      it 'raises RetryableError for rate limit' do
        dossier = create(:dossier, :with_entreprise)
        etablissement = dossier.etablissement

        expect { ErrorJob.perform_now(etablissement) }
          .to raise_error(APIEntreprise::Job::RetryableError, /rate limited \(pool #{pool}\)/)
      end
    end

    context 'when job is not in PING_KEY_BY_JOB (fail-open)' do
      it 'skips health check and proceeds' do
        # ErrorJob is not in PING_KEY_BY_JOB, so ping_key_for_job returns nil
        allow(APIEntreprise::RateLimiter).to receive(:throttled?).and_return(false)

        dossier = create(:dossier, :with_entreprise)
        etablissement = dossier.etablissement

        # Job runs (raises from adapter, not from before_perform)
        expect { ErrorJob.perform_now(etablissement) }.to raise_error(StandardError, /API Entreprise error/)
      end
    end
  end

  describe '#api_pool' do
    it 'returns the correct pool for each job class' do
      expect(APIEntreprise::ExtraitKbisJob.new.api_pool).to eq(250)
      expect(APIEntreprise::TvaJob.new.api_pool).to eq(250)
      expect(APIEntreprise::ExercicesJob.new.api_pool).to eq(250)
      expect(APIEntreprise::AssociationJob.new.api_pool).to eq(250)
      expect(APIEntreprise::BilansBdfJob.new.api_pool).to eq(250)
      expect(APIEntreprise::EffectifsJob.new.api_pool).to eq(50)
      expect(APIEntreprise::EffectifsAnnuelsJob.new.api_pool).to eq(50)
      expect(APIEntreprise::AttestationSocialeJob.new.api_pool).to eq(100)
      expect(APIEntreprise::AttestationFiscaleJob.new.api_pool).to eq(5)
    end

    it 'defaults to 250 for unknown job classes' do
      expect(ErrorJob.new.api_pool).to eq(250)
    end
  end

  describe '#ping_key_for_job' do
    it 'returns the correct ping key for each job class' do
      expect(APIEntreprise::ExtraitKbisJob.new.ping_key_for_job).to eq('infogreffe/rcs')
      expect(APIEntreprise::TvaJob.new.ping_key_for_job).to eq('dgfip/numero_tva')
      expect(APIEntreprise::AssociationJob.new.ping_key_for_job).to eq('djepva/api-association')
      expect(APIEntreprise::ExercicesJob.new.ping_key_for_job).to eq('dgfip/chiffre_affaires')
      expect(APIEntreprise::EffectifsJob.new.ping_key_for_job).to eq('gip_mds/effectifs')
      expect(APIEntreprise::EffectifsAnnuelsJob.new.ping_key_for_job).to eq('gip_mds/effectifs')
      expect(APIEntreprise::AttestationSocialeJob.new.ping_key_for_job).to eq('urssaf/attestation_sociale')
      expect(APIEntreprise::AttestationFiscaleJob.new.ping_key_for_job).to eq('dgfip/attestation_fiscale')
      expect(APIEntreprise::BilansBdfJob.new.ping_key_for_job).to eq('banque_de_france/bilans')
    end

    it 'returns nil for unknown job classes (fail-open)' do
      expect(ErrorJob.new.ping_key_for_job).to be_nil
    end
  end

  describe 'PING_KEY_BY_JOB completeness' do
    it 'covers all job classes in app/jobs/api_entreprise/' do
      job_class_names = Rails.root.glob('app/jobs/api_entreprise/*_job.rb')
        .map { "APIEntreprise::#{File.basename(it, '.rb').camelize}".constantize }
        .filter { it < described_class }
        .map { it.name.demodulize }

      expect(described_class::PING_KEY_BY_JOB.keys).to match_array(job_class_names)
    end
  end

  describe '#with_adapter' do
    let(:job) { described_class.new }
    let(:adapter) { instance_double(APIEntreprise::Adapter) }

    context 'when adapter returns Success with data' do
      before { allow(adapter).to receive(:to_params).and_return(Dry::Monads::Success({ siret: '123' })) }

      it 'yields the params' do
        result = nil
        job.send(:with_adapter, adapter) { |params| result = params }
        expect(result).to eq({ siret: '123' })
      end
    end

    context 'when adapter returns Failure with forbidden (privilege not available)' do
      before { allow(adapter).to receive(:to_params).and_return(Dry::Monads::Failure(type: :forbidden, code: 403, retryable: false, raw_response: nil)) }

      it 'does not yield and logs' do
        yielded = false
        job.send(:with_adapter, adapter) { |_| yielded = true }
        expect(yielded).to be false
      end
    end

    context 'when adapter returns Failure with retryable error' do
      let(:response) do
        Typhoeus::Response.new(
          effective_url: 'http://host.com/path', code: '503', body: 'error',
          return_message: 'timeout', total_time: 10, connect_time: 20, headers: ''
        )
      end

      before do
        allow(adapter).to receive(:to_params)
          .and_return(Dry::Monads::Failure(type: :service_unavailable, code: 503, retryable: true, raw_response: response))
      end

      it 're-raises to trigger job retry' do
        expect { job.send(:with_adapter, adapter) { |_| } }.to raise_error(StandardError, /API Entreprise error:/)
      end
    end

    context 'when adapter returns Failure with retryable error but nil response' do
      before do
        allow(adapter).to receive(:to_params)
          .and_return(Dry::Monads::Failure(type: :token, code: 401, retryable: true, raw_response: nil))
      end

      it 'raises a StandardError with diagnostic message' do
        expect { job.send(:with_adapter, adapter) { |_| } }
          .to raise_error(StandardError, /API Entreprise error: type=token code=401/)
      end
    end

    context 'when adapter returns Failure with rate_limited' do
      before do
        allow(adapter).to receive(:to_params)
          .and_return(Dry::Monads::Failure(type: :rate_limited, code: 429, retryable: true, raw_response: nil))
      end

      it 'raises RetryableError for Sidekiq exponential backoff' do
        expect { job.send(:with_adapter, adapter) { |_| } }
          .to raise_error(APIEntreprise::Job::RetryableError, /rate limited by API/)
      end
    end

    context 'when adapter returns Failure with non-retryable error' do
      before do
        allow(adapter).to receive(:to_params)
          .and_return(Dry::Monads::Failure(type: :unavailable_for_legal_reasons, code: 451, retryable: false, raw_response: nil))
      end

      it 'does not raise and returns nil' do
        result = job.send(:with_adapter, adapter) { |_| 'should not reach' }
        expect(result).to be_nil
      end

      it 'logs the non-retryable failure' do
        expect(Rails.logger).to receive(:info).with(/non-retryable.*type=unavailable_for_legal_reasons.*code=451/)
        job.send(:with_adapter, adapter) { |_| }
      end
    end
  end

  describe 'sidekiq retry configuration' do
    subject(:options) { described_class.get_sidekiq_options }

    it 'defers Sentry reporting until the 8th attempt while keeping native retry' do
      expect(options["attempt_threshold"]).to eq(8)
      expect(options["retry"]).to eq(ActiveJob::RetryOnStandardError::MAX_ATTEMPTS_JOBS)
    end
  end

  class ErrorJob < APIEntreprise::Job
    include Dry::Monads[:result]

    def perform(etablissement)
      @etablissement = etablissement
      adapter = Struct.new(:to_params).new(Failure(type: :service_unavailable, code: 503, retryable: true, raw_response: nil))
      with_adapter(adapter) { |_| }
    end
  end
end
