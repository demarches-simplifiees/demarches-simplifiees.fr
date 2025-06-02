# frozen_string_literal: true

describe Cron::ReleaseCrashedExportJob do
  let(:handler) { "whocares" }

  def locked_by(hostname)
    "delayed_job.33 host:#{hostname} pid:1252488"
  end

  describe '.perform' do
    subject { described_class.new.perform }
    let!(:job) { Delayed::Job.create!(handler:, queue: ExportJob.queue_name, locked_by: locked_by(Socket.gethostname)) }

    it 'releases lock' do
      expect { subject }.to change { job.reload.locked_by }.from(anything).to(nil)
    end
    it 'increases attempts' do
      expect { subject }.to change { job.reload.attempts }.by(1)
    end
  end

  describe '.hostname_and_pid' do
    subject { described_class.new.hostname_and_pid(Delayed::Worker.new.name) }
    it 'extract hostname and pid from worker.name' do
      hostname, pid = subject

      expect(hostname).to eq(Socket.gethostname)
      expect(pid).to eq(Process.pid.to_s)
    end
  end

  describe 'whoami' do
    subject { described_class.new.whoami }
    it { is_expected.to eq(Socket.gethostname) }
  end

  describe 'jobs_for_current_host' do
    subject { described_class.new.jobs_for_current_host }

    context 'when jobs run an another host' do
      let!(:job) { Delayed::Job.create!(handler:, queue: :default, locked_by: locked_by('spec1.prod')) }
      it { is_expected.to be_empty }
    end

    context 'when jobs run an same host with default queue' do
      let!(:job) { Delayed::Job.create!(handler:, queue: :default, locked_by: locked_by(Socket.gethostname)) }
      it { is_expected.to be_empty }
    end

    context 'when jobs run an same host with exports queue' do
      let!(:job) { Delayed::Job.create!(handler:, queue: ExportJob.queue_name, locked_by: locked_by(Socket.gethostname)) }
      it { is_expected.to include(job) }
    end
  end
end
