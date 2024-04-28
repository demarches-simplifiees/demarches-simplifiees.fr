# frozen_string_literal: true

describe Cron::ExpiredUsersDeletionJob do
  subject { described_class.perform_now }

  context 'when env[EXPIRE_USER_DELETION_JOB_LIMIT] is present' do
    before { expect(ENV).to receive(:[]).with('EXPIRE_USER_DELETION_JOB_LIMIT').and_return('anything') }

    it 'calls Expired::UsersDeletionService.process_expired' do
      expect_any_instance_of(Expired::UsersDeletionService).to receive(:process_expired)
      subject
    end

    it 'fails gracefuly by catching any error (to prevent re-enqueue and sending too much email)' do
      expect_any_instance_of(Expired::UsersDeletionService).to receive(:process_expired).and_raise(StandardError)
      expect { subject }.not_to raise_error
    end
  end

  context 'when env[EXPIRE_USER_DELETION_JOB_LIMIT] is absent' do
    it 'does not call Expired::UsersDeletionService.process_expired' do
      expect_any_instance_of(Expired::UsersDeletionService).not_to receive(:process_expired)
      subject
    end
  end
end
