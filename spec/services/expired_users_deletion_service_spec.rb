describe ExpiredUsersDeletionService do
  let(:mail_double) do
    dbl = double()
    expect(dbl).to receive(:deliver_later).with(wait: 0)
    dbl
  end

  before { user && dossier }

  describe '#process_expired' do
    subject { ExpiredUsersDeletionService.new.process_expired }

    context 'when user has an expirable dossier' do
      let(:dossier) { create(:dossier, user:, created_at: 3.years.ago) }

      context 'when user was not notified' do
        let(:user) { create(:user, inactive_close_to_expiration_notice_sent_at: nil) }

        it 'update user.inactive_close_to_expiration_notice_sent_at ' do
          expect(UserMailer).to receive(:notify_inactive_close_to_deletion).with(user).and_return(mail_double)
          expect { subject }
            .to change { user.reload.inactive_close_to_expiration_notice_sent_at }
            .from(nil).to(anything)
        end
      end

      context 'user has been notified 1 week ago' do
        let(:user) { create(:user, inactive_close_to_expiration_notice_sent_at: 1.week.ago) }

        it 'do nothing' do
          expect { subject }.not_to change { Dossier.count }
          expect { user.reload }.not_to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'user has been notified 3 weeks ago' do
        let(:user) { create(:user, inactive_close_to_expiration_notice_sent_at: 3.weeks.ago) }

        it 'destroys user and dossier' do
          expect { subject }.to change { Dossier.count }.by(-1)
          expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when user is expirable' do
      let(:dossier) { nil }

      context 'when user was not notified' do
        let(:user) { create(:user, last_sign_in_at: 3.years.ago, inactive_close_to_expiration_notice_sent_at: nil) }

        it 'update user.inactive_close_to_expiration_notice_sent_at ' do
          expect(UserMailer).to receive(:notify_inactive_close_to_deletion).with(user).and_return(mail_double)
          expect { subject }
            .to change { user.reload.inactive_close_to_expiration_notice_sent_at }
            .from(nil).to(anything)
        end
      end

      context 'when user has been notified 1 week ago' do
        let(:user) { create(:user, last_sign_in_at: 3.years.ago, inactive_close_to_expiration_notice_sent_at: 1.week.ago) }

        it 'do nothing' do
          expect { subject }.not_to change { Dossier.count }
          expect { user.reload }.not_to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when user has been notified 3 weeks ago' do
        let(:user) { create(:user, last_sign_in_at: 3.years.ago, inactive_close_to_expiration_notice_sent_at: 3.weeks.ago) }

        it 'destroys user and dossier' do
          subject
          expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe '#expiring_users_without_dossiers' do
    let(:dossier) { nil }
    subject { ExpiredUsersDeletionService.new.expiring_users_without_dossiers }

    context 'when user last_sign_in_at is 1 year ago and has no dossier' do
      let(:user) { create(:user, last_sign_in_at: 1.year.ago) }
      it { is_expected.not_to include(user) }
    end

    context 'when user last_sign_in_at is 3 year ago and has no dossier' do
      let(:user) { create(:user, last_sign_in_at: 3.years.ago) }
      it { is_expected.to include(user) }
    end
  end

  describe '#expiring_users_with_dossiers' do
    let(:user) { create(:user) }
    subject { ExpiredUsersDeletionService.new.expiring_users_with_dossiers }

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
