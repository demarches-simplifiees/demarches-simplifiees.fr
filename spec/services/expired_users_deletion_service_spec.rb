describe ExpiredUsersDeletionService do
  let(:user) { create(:user) }
  before { user && dossier }

  describe '#process_expired' do
    subject { ExpiredUsersDeletionService.process_expired }
    context 'when user has a dossier created 1 year ago' do
      let(:dossier) { create(:dossier, user:, created_at: 1.year.ago) }
      it 'does not destroy anything' do
        expect { subject }.not_to change { Dossier.count }
        expect(user.reload).to be_truthy
      end
    end

    context 'when user has a dossier created 3 years ago' do
      let(:dossier) { create(:dossier, user:, created_at: 3.years.ago) }
      it 'destroys user and dossier' do
        expect { subject }.to change { Dossier.count }.by(-1)
        expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#find_expired_user' do
    subject { ExpiredUsersDeletionService.find_expired_user }

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
