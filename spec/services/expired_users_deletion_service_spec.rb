describe ExpiredUsersDeletionService do
  let(:last_signed_in_not_expired) { (ExpiredUsersDeletionService::EXPIRABLE_AFTER_IN_YEAR - 1).years.ago }
  let(:last_signed_in_expired) { (ExpiredUsersDeletionService::EXPIRABLE_AFTER_IN_YEAR + 1).years.ago }
  let(:before_close_to_expiration) { nil }
  let(:notified_close_to_expiration) { (ExpiredUsersDeletionService::RETENTION_AFTER_NOTICE_IN_WEEK - 1).weeks.ago }
  let(:due_close_to_expiration) { (ExpiredUsersDeletionService::RETENTION_AFTER_NOTICE_IN_WEEK + 1).weeks.ago }
  let(:mail_double) do
    dbl = double()
    expect(dbl).to receive(:deliver_later).with(wait: 0)
    dbl
  end

  before { user && dossier }

  describe '#process_expired' do
    subject { ExpiredUsersDeletionService.new.process_expired }

    context 'when user has an expirable dossier' do
      let(:dossier) { create(:dossier, user:, created_at: last_signed_in_expired) }

      context 'when user was not notified' do
        let(:user) { create(:user, inactive_close_to_expiration_notice_sent_at: before_close_to_expiration) }

        it 'update user.inactive_close_to_expiration_notice_sent_at ' do
          expect(UserMailer).to receive(:notify_inactive_close_to_deletion).with(user).and_return(mail_double)
          expect { subject }
            .to change { user.reload.inactive_close_to_expiration_notice_sent_at }
            .from(nil).to(anything)
        end
      end

      context 'user has been notified 1 week ago' do
        let(:user) { create(:user, inactive_close_to_expiration_notice_sent_at: notified_close_to_expiration) }

        it 'do nothing' do
          expect { subject }.not_to change { Dossier.count }
          expect { user.reload }.not_to raise_error
        end
      end

      context 'user has been notified 3 weeks ago' do
        let(:user) { create(:user, inactive_close_to_expiration_notice_sent_at: due_close_to_expiration) }

        it 'destroys user and dossier' do
          expect { subject }.to change { Dossier.count }.by(-1)
          expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when user is expirable' do
      let(:dossier) { nil }

      context 'when user was not notified' do
        let(:user) { create(:user, last_sign_in_at: last_signed_in_expired, inactive_close_to_expiration_notice_sent_at: before_close_to_expiration) }

        it 'update user.inactive_close_to_expiration_notice_sent_at ' do
          expect(UserMailer).to receive(:notify_inactive_close_to_deletion).with(user).and_return(mail_double)
          expect { subject }
            .to change { user.reload.inactive_close_to_expiration_notice_sent_at }
            .from(nil).to(anything)
        end
      end

      context 'when user has been notified 1 week ago' do
        let(:user) { create(:user, last_sign_in_at: last_signed_in_expired, inactive_close_to_expiration_notice_sent_at: notified_close_to_expiration) }

        it 'do nothing' do
          expect { subject }.not_to change { Dossier.count }
          expect { user.reload }.not_to raise_error
        end
      end

      context 'when user has been notified 3 weeks ago' do
        let(:user) { create(:user, last_sign_in_at: last_signed_in_expired, inactive_close_to_expiration_notice_sent_at: due_close_to_expiration) }

        it 'destroys user and dossier' do
          subject
          expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe '#expiring_users_without_dossiers' do
    let(:dossier) { nil }
    subject { ExpiredUsersDeletionService.new.send(:expiring_users_without_dossiers) }

    context 'when user last_sign_in_at is 1 year ago and has no dossier' do
      let(:user) { create(:user, last_sign_in_at: last_signed_in_not_expired) }
      it { is_expected.not_to include(user) }
    end

    context 'when user last_sign_in_at is 3 year ago and has no dossier' do
      let(:user) { create(:user, last_sign_in_at: last_signed_in_expired) }
      it { is_expected.to include(user) }
    end

    context 'when expert last sign in at is 3 years ago' do
      let(:user) { create(:user, expert: create(:expert), last_sign_in_at: last_signed_in_expired) }
      it { is_expected.not_to include(user) }
    end

    context 'when instructeur last sign in at is 3 years ago' do
      let(:user) { create(:user, instructeur: create(:instructeur), last_sign_in_at: last_signed_in_expired) }
      it { is_expected.not_to include(user) }
    end

    context 'when admin last sign in at is 3 years ago' do
      let(:user) { create(:user, administrateur: create(:administrateur), last_sign_in_at: last_signed_in_expired) }
      it { is_expected.not_to include(user) }
    end
  end

  describe '#expiring_users_with_dossiers' do
    let(:user) { create(:user) }
    subject { ExpiredUsersDeletionService.new.send(:expiring_users_with_dossiers) }

    context 'when user has a dossier created 1 year ago' do
      let(:dossier) { create(:dossier, user:, created_at: last_signed_in_not_expired) }
      it { is_expected.not_to include(user) }
    end

    context 'when user has a dossier created 3 years ago' do
      let(:dossier) { create(:dossier, user:, created_at: last_signed_in_expired) }
      it { is_expected.to include(user) }
    end

    context 'when user one dossier created 3 years ago and one dossier created 1 year ago' do
      let(:dossier) { create(:dossier, :brouillon, user:, created_at: last_signed_in_expired) }
      it 'respects the HAVING MAX(dossier.created_at) ignores the user' do
        create(:dossier, :brouillon, user:, created_at: last_signed_in_not_expired)
        is_expected.not_to include(user)
      end
    end

    context 'when expert last sign in at is 3 years ago' do
      let(:dossier) { create(:dossier, user:, created_at: last_signed_in_expired) }
      let(:user) { create(:user, expert: create(:expert), last_sign_in_at: last_signed_in_expired) }
      it { is_expected.not_to include(user) }
    end

    context 'when instructeur last sign in at is 3 years ago' do
      let(:dossier) { create(:dossier, user:, created_at: last_signed_in_expired) }
      let(:user) { create(:user, instructeur: create(:instructeur), last_sign_in_at: last_signed_in_expired) }
      it { is_expected.not_to include(user) }
    end

    context 'when admin last sign in at is 3 years ago' do
      let(:dossier) { create(:dossier, user:, created_at: last_signed_in_expired) }
      let(:user) { create(:user, administrateur: create(:administrateur), last_sign_in_at: last_signed_in_expired) }
      it { is_expected.not_to include(user) }
    end
  end
end
