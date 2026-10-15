# frozen_string_literal: true

RSpec.describe Cron::RetryParkedAPIEntrepriseFetchesJob, type: :job do
  let(:procedure) { procedures.entreprise }
  let(:etablissement) { create(:etablissement) }
  let(:job) { 'ExercicesJob' }
  let(:updated_at) { 3.hours.ago }
  let!(:fetch) do
    ParkedAPIEntrepriseFetch.create!(etablissement:, job:, procedure:, arguments: [etablissement.id, procedure.id], code: 503, updated_at:)
  end

  before do
    procedure.update!(api_entreprise_token: JWT.encode({ exp: 2.months.from_now.to_i }, nil, 'none'))
    allow(APIEntreprise::HealthChecker).to receive(:provider_up?).and_return(true)
    allow(APIEntreprise::RateLimiter).to receive(:throttled?).and_return(false)
  end

  it 'runs every two hours, after the champ crons' do
    expect(described_class.cron_expression).to start_with('45 ')
  end

  it 'gives the replays of a pool 20% of it for the two hours until the next run' do
    expect(described_class.batch_size(250)).to eq(6_000)
    expect(described_class.batch_size(5)).to eq(120)
  end

  it 'replays the job in the low queue, spread until the next run' do
    freeze_time do
      expect { described_class.perform_now }
        .to have_enqueued_job(APIEntreprise::ExercicesJob)
        .with(etablissement.id, procedure.id)
        .on_queue('low')
        .at(a_value_between(Time.current, 110.minutes.from_now))
    end
  end

  it 'marks the line as in the queue so the next run does not replay it twice' do
    freeze_time do
      expect { described_class.perform_now }.to change { fetch.reload.enqueued_at }.from(nil).to(Time.current)
    end
  end

  context 'with a job taking more arguments' do
    let(:job) { 'EffectifsAnnuelsJob' }

    before { fetch.update_column(:arguments, [etablissement.id, procedure.id, 2025]) }

    it 'replays it with all of them' do
      expect { described_class.perform_now }
        .to have_enqueued_job(APIEntreprise::EffectifsAnnuelsJob).with(etablissement.id, procedure.id, 2025)
    end
  end

  context 'when the queue cannot be reached' do
    before { allow(ActiveJob).to receive(:perform_all_later).and_raise(RedisClient::CannotConnectError) }

    it 'leaves the line for the retry of the cron' do
      expect { described_class.perform_now }.to raise_error(RedisClient::CannotConnectError)
      expect(fetch.reload.enqueued_at).to be_nil
    end
  end

  context 'when the queue goes down in the middle of the batch' do
    let!(:newer_fetch) do
      ParkedAPIEntrepriseFetch.create!(etablissement: create(:etablissement), job:, procedure:, arguments: [0, procedure.id], code: 503, updated_at:, created_at: 1.minute.from_now)
    end

    before do
      stub_const("#{described_class}::ENQUEUED_TOGETHER", 1)
      calls = 0
      allow(ActiveJob).to receive(:perform_all_later).and_wrap_original do |original, jobs|
        calls += 1
        raise RedisClient::CannotConnectError if calls == 2

        original.call(jobs)
      end
    end

    it 'marks only the lines already sent' do
      expect { described_class.perform_now }.to raise_error(RedisClient::CannotConnectError)
      expect(fetch.reload.enqueued_at).to be_present
      expect(newer_fetch.reload.enqueued_at).to be_nil
    end
  end

  context 'with a line whose arguments can no longer be read' do
    let!(:unreadable_fetch) do
      ParkedAPIEntrepriseFetch.create!(etablissement: create(:etablissement), job:, procedure:, arguments: [{ '_aj_globalid' => "gid://#{GlobalID.app}/Dossier/0" }], code: 503, updated_at:)
    end

    it 'still replays the other lines' do
      expect { described_class.perform_now }.to have_enqueued_job(APIEntreprise::ExercicesJob).with(etablissement.id, procedure.id).exactly(:once)
      expect(fetch.reload.enqueued_at).to be_present
      expect(unreadable_fetch.reload.enqueued_at).to be_nil
    end
  end

  context 'when the job failed again less than two hours ago' do
    let(:updated_at) { 1.hour.ago }

    it { expect { described_class.perform_now }.not_to have_enqueued_job }
  end

  context 'when the replayed job is still waiting in a late queue' do
    before { fetch.update_column(:enqueued_at, 3.hours.ago) }

    it { expect { described_class.perform_now }.not_to have_enqueued_job }
  end

  context 'when the replayed job never ran for a day' do
    before { fetch.update_column(:enqueued_at, 25.hours.ago) }

    it 'considers it lost and replays it' do
      expect { described_class.perform_now }.to have_enqueued_job(APIEntreprise::ExercicesJob).with(etablissement.id, procedure.id)
    end
  end

  context 'while its provider is down' do
    before { allow(APIEntreprise::HealthChecker).to receive(:provider_up?).with('dgfip/chiffre_affaires').and_return(false) }

    it { expect { described_class.perform_now }.not_to have_enqueued_job }
  end

  context 'while its pool is throttled' do
    before { allow(APIEntreprise::RateLimiter).to receive(:throttled?).with(250).and_return(true) }

    it { expect { described_class.perform_now }.not_to have_enqueued_job }
  end

  context 'when API Entreprise rejected the token of the procedure' do
    before { procedure.update_column(:api_entreprise_token_rejected_at, 1.hour.ago) }

    it { expect { described_class.perform_now }.not_to have_enqueued_job }
  end

  context 'with more waiting jobs than the batch allows' do
    let(:other_etablissement) { create(:etablissement) }
    let!(:newer_fetch) do
      ParkedAPIEntrepriseFetch.create!(etablissement: other_etablissement, job:, procedure:, arguments: [other_etablissement.id, procedure.id], code: 503, updated_at:, created_at: 1.minute.from_now)
    end

    before { allow(described_class).to receive(:batch_size).and_return(1) }

    it 'replays the oldest first and leaves the rest for the next run' do
      expect { described_class.perform_now }
        .to have_enqueued_job(APIEntreprise::ExercicesJob).with(etablissement.id, procedure.id).exactly(:once)
      expect(APIEntreprise::ExercicesJob).not_to have_been_enqueued.with(other_etablissement.id, procedure.id)
    end
  end

  context 'with jobs sharing the same pool' do
    let!(:tva_fetch) do
      ParkedAPIEntrepriseFetch.create!(etablissement:, job: 'TvaJob', procedure:, arguments: [etablissement.id, procedure.id], code: 503, updated_at:, created_at: 1.minute.from_now)
    end

    it 'shares one batch between them, the oldest first' do
      allow(described_class).to receive(:batch_size).with(250).and_return(1)

      expect { described_class.perform_now }.to have_enqueued_job(APIEntreprise::ExercicesJob).exactly(:once)
      expect(APIEntreprise::TvaJob).not_to have_been_enqueued
    end

    it 'still replays a job whose provider is up when the other one is down' do
      allow(APIEntreprise::HealthChecker).to receive(:provider_up?).with('dgfip/chiffre_affaires').and_return(false)

      expect { described_class.perform_now }.to have_enqueued_job(APIEntreprise::TvaJob).with(etablissement.id, procedure.id)
      expect(APIEntreprise::ExercicesJob).not_to have_been_enqueued
    end
  end

  context 'with a line left by a job that no longer exists' do
    before do
      ParkedAPIEntrepriseFetch.create!(etablissement: create(:etablissement), job: 'RemovedJob', procedure:, arguments: [], code: 503, updated_at:)
    end

    it 'still replays the other jobs' do
      expect { described_class.perform_now }.to have_enqueued_job(APIEntreprise::ExercicesJob).with(etablissement.id, procedure.id)
    end
  end

  context 'when the job has been waiting for more than a month' do
    before { fetch.update_column(:created_at, 32.days.ago) }

    it 'gives up on it and reports how many fetches of each job were lost' do
      expect(Sentry).to receive(:capture_message)
        .with('API Entreprise complementary fetches given up after a month of failures',
          level: :error, extra: { purged_by_job: { 'ExercicesJob' => 1 } })

      described_class.perform_now

      expect(ParkedAPIEntrepriseFetch.where(id: fetch.id)).to be_empty
    end
  end

  context 'when the month is over since this morning only' do
    before { fetch.update_column(:created_at, Time.zone.parse('2026-09-14 08:00')) }

    it 'waits for the first run of the next day, so the lines of a day are reported once' do
      travel_to(Time.zone.parse('2026-10-14 10:45')) do
        expect(Sentry).not_to receive(:capture_message)

        described_class.perform_now

        expect(ParkedAPIEntrepriseFetch.where(id: fetch.id)).to exist
      end
    end
  end

  context 'when no job has been waiting for more than a month' do
    it 'reports nothing' do
      expect(Sentry).not_to receive(:capture_message)

      described_class.perform_now
    end
  end
end
