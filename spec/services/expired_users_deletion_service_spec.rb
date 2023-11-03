describe ExpiredUsersDeletionService do
  let(:user) { create(:user) }
  before { user && dossier }

  describe '#process_expired' do
    context 'when user has not been notified' do
      subject { ExpiredUsersDeletionService.process_expired }

      context 'when user has a dossier created 3 years ago' do
        let(:dossier) { create(:dossier, user:, created_at: 3.years.ago) }
        it 'update user.inactive_close_to_expiration_notice_sent_at ' do
          expect(UserMailer).to receive(:notify_inactive_close_to_deletion).with(user).and_return(double(perform_later: true))
          expect { subject }
            .to change { user.reload.inactive_close_to_expiration_notice_sent_at }
            .from(nil).to(anything)
        end
      end
    end

    context 'when user has been notified 1 week ago' do
      before { user.update(inactive_close_to_expiration_notice_sent_at: 1.week.ago) }
      subject { ExpiredUsersDeletionService.process_expired }

      context 'when user has a dossier created 3 years ago' do
        let(:dossier) { create(:dossier, user:, created_at: 3.years.ago) }
        it 'do nothing' do
          expect { subject }.not_to change { Dossier.count }
          expect { user.reload }.not_to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when user has been notified 3 weeks ago' do
      before { user.update(inactive_close_to_expiration_notice_sent_at: 3.weeks.ago) }
      subject { ExpiredUsersDeletionService.process_expired }

      context 'when user has a dossier created 3 years ago' do
        let(:dossier) { create(:dossier, user:, created_at: 3.years.ago) }
        it 'destroys user and dossier' do
          expect { subject }.to change { Dossier.count }.by(-1)
          expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe '#expiring_users' do
    subject { ExpiredUsersDeletionService.expiring_users }

    context 'when user has no dossiers (TODO: just drop all user without dossier, no need to alert them)' do
      let(:dossier) { nil }
      xit { is_expected.to include(user) }
    end

    context 'when user has a dossier created 1 year ago' do
      let(:dossier) { create(:dossier, user:, created_at: 1.year.ago) }
      it { is_expected.not_to include(user) }
    end

    context 'when user has a dossier created 3 years ago' do
      let(:dossier) { create(:dossier, user:, created_at: 3.years.ago) }
      it { is_expected.to include(user) }
    end
  end
end
