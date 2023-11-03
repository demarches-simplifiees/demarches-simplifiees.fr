describe Cron::ExpiredUsersDeletionJob do
  subject { described_class.perform_now }

  context 'when env[EXPIRE_USER_DELETION_JOB_DISABLED] is present' do
    before { expect(ENV).to receive(:[]).with('EXPIRE_USER_DELETION_JOB_DISABLED').and_return('anything') }

    it 'does not call ExpiredUsersDeletionService.process_expired' do
      expect(ExpiredUsersDeletionService).not_to receive(:process_expired)
      subject
    end
  end

  context 'when env[EXPIRE_USER_DELETION_JOB_DISABLED] is absent' do
    it 'calls ExpiredUsersDeletionService.process_expired' do
      expect(ExpiredUsersDeletionService).to receive(:process_expired)
      subject
    end
  end
end
