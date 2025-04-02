# frozen_string_literal: true

require 'rails_helper'

describe DelayedPurgeJob, type: :job do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
  let!(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:blob) { dossier.champs.first.piece_justificative_file.first.blob }
  let(:job) { described_class.new(blob) }
  let(:client) { double('OpenStack client') }
  let(:pool) { double('ConnectionPool') }

  before do
    stub_const('ENV', ENV.to_hash.merge('PURGE_LATER_DELAY_IN_DAY' => '1'))
  end

  let(:subject) { job.perform_now }

  it 'emit request instead of destroying it' do
    container = "bucket"
    double_service = double(container:)
    allow_any_instance_of(ActiveStorage::Blob).to receive(:service).and_return(double_service)

    allow(OpenStackStorage).to receive(:with_client).and_yield(client)

    expect(client).to receive(:copy_object)
      .with(container, blob.key, container, blob.key, { 'X-Delete-At' => anything, "Content-Type" => blob.content_type })
      .and_return(double(status: 201))

    allow(described_class).to receive(:openstack?).and_return(true)

    subject

    perform_enqueued_jobs
  end

  context 'when destroying an instance' do
    it 'uses our custom job' do
      expect { dossier.destroy }.to have_enqueued_job(DelayedPurgeJob)
    end
  end
end
