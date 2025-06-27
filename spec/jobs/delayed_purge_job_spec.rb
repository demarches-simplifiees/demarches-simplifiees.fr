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

  context 'emit request instead of destroying it' do
    let(:container) { "bucket" }
    let(:client) { double("client") }
    let(:double_service) { double(container:) }
    let(:cloned_dossier) { dossier.clone }

    before do
      allow_any_instance_of(ActiveStorage::Blob).to receive(:service).and_return(double_service)
      allow_any_instance_of(DelayedPurgeJob).to receive(:client).and_return(client)
      allow(described_class).to receive(:openstack?).and_return(true)
    end

    it 'with attachments' do
      expect(client).not_to receive(:copy_object)
      subject
      perform_enqueued_jobs
    end

    it 'without attachments' do
      dossier.champs.first.piece_justificative_file.first.delete
      expect(client).to receive(:copy_object)
        .with(container, blob.key, container, blob.key, { 'X-Delete-At' => anything, "Content-Type" => blob.content_type })
        .and_return(double(status: 201))
      subject
      perform_enqueued_jobs
    end

    it 'with cloned dossier' do
      expect { cloned_dossier.destroy }.to have_enqueued_job(DelayedPurgeJob)
      perform_enqueued_jobs

      expect(client).to receive(:copy_object)
        .with(container, blob.key, container, blob.key, { 'X-Delete-At' => anything, "Content-Type" => blob.content_type })
        .and_return(double(status: 201))

      expect { dossier.destroy }.to have_enqueued_job(DelayedPurgeJob)
      perform_enqueued_jobs
    end
  end

  context 'when destroying an instance' do
    it 'uses our custom job' do
      expect { dossier.destroy }.to have_enqueued_job(DelayedPurgeJob)
      perform_enqueued_jobs
    end
  end
end
