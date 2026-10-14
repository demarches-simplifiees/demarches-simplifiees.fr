# frozen_string_literal: true

RSpec.describe ParkedAPIEntrepriseFetch do
  let(:etablissement) { create(:etablissement) }
  let(:procedure) { procedures.entreprise }
  let(:fetch) { described_class.find_by(etablissement:, job: 'ExercicesJob') }

  def park(code, job: 'ExercicesJob', arguments: [etablissement.id, procedure.id])
    described_class.park!(etablissement_id: etablissement.id, job:, procedure_id: procedure.id, arguments:, code:)
  end

  describe '.park!' do
    it 'remembers the job to replay' do
      park(503)

      expect(fetch).to have_attributes(procedure_id: procedure.id, code: 503, attempts: 1)
    end

    it 'keeps the arguments of the job to replay it as it was' do
      park(503, arguments: [etablissement.id, procedure.id, 2025])

      expect(fetch.job_arguments).to eq([etablissement.id, procedure.id, 2025])
    end

    it 'counts a new failure without forgetting when the wait began' do
      travel_to(2.days.ago) { park(503) }
      parked_at = fetch.created_at

      park(429, arguments: [etablissement.id, procedure.id, 2025])

      expect(fetch.reload).to have_attributes(attempts: 2, code: 429, created_at: parked_at)
      expect(fetch.job_arguments).to eq([etablissement.id, procedure.id, 2025])
      expect(fetch.updated_at).to be > parked_at
    end

    it 'waits for the cron again once the replayed job fails' do
      park(503)
      fetch.update_column(:enqueued_at, 1.hour.ago)

      park(503)

      expect(fetch.reload.enqueued_at).to be_nil
    end

    it 'keeps one line per job' do
      park(503)
      park(503, job: 'TvaJob')

      expect(described_class.where(etablissement:).pluck(:job)).to contain_exactly('ExercicesJob', 'TvaJob')
    end
  end

  describe '.release!' do
    it 'forgets the job' do
      park(503)

      described_class.release!(etablissement_id: etablissement.id, job: 'ExercicesJob')

      expect(fetch).to be_nil
    end

    it 'does nothing when the job was not waiting' do
      expect { described_class.release!(etablissement_id: etablissement.id, job: 'ExercicesJob') }.not_to raise_error
    end
  end

  it 'goes away with its etablissement' do
    park(503)

    etablissement.destroy!

    expect(described_class.where(etablissement_id: etablissement.id)).to be_empty
  end
end
