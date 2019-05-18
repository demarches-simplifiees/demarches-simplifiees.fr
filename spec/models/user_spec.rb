require 'spec_helper'

describe User, type: :model do
  describe '#after_confirmation' do
    let(:email) { 'mail@beta.gouv.fr' }
    let!(:invite) { create(:invite, email: email) }
    let!(:invite2) { create(:invite, email: email) }
    let(:user) do
      create(:user,
             email: email,
             password: 'démarches-simplifiées pwd',
             confirmation_token: '123',
             confirmed_at: nil)
    end

    it 'when confirming a user, it links the pending invitations to this user' do
      expect(user.invites.size).to eq(0)
      user.confirm
      expect(user.reload.invites.size).to eq(2)
    end
  end

  describe '#owns?' do
    let(:owner) { create(:user) }
    let(:dossier) { create(:dossier, user: owner) }
    let(:invite_user) { create(:user) }
    let(:invite_gestionnaire) { create(:user) }

    subject { user.owns?(dossier) }

    context 'when user is owner' do
      let(:user) { owner }

      it { is_expected.to be_truthy }
    end

    context 'when user was invited by user' do
      before do
        create(:invite, dossier: dossier, user: invite_user)
      end

      let(:user) { invite_user }

      it { is_expected.to be_falsy }
    end

    context 'when user is quidam' do
      let(:user) { create(:user) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#password_complexity' do
    let(:email) { 'mail@beta.gouv.fr' }
    let(:passwords) { ['pass', '12pass23', 'démarches ', 'démarches-simple', 'démarches-simplifiées pwd'] }
    let(:user) { build(:user, email: email, password: password, confirmation_token: '123', confirmed_at: nil) }
    let(:min_complexity) { PASSWORD_COMPLEXITY_FOR_USER }

    subject do
      user.save
      user.errors.full_messages
    end

    context 'when password is too short' do
      let(:password) { 's' * (PASSWORD_MIN_LENGTH - 1) }

      it { expect(subject).to eq(["Le mot de passe est trop court"]) }
    end

    context 'when password is too simple' do
      let(:password) { passwords[min_complexity - 1] }

      it { expect(subject).to eq(["Le mot de passe n'est pas assez complexe"]) }
    end

    context 'when password is acceptable' do
      let(:password) { passwords[min_complexity] }

      it { expect(subject).to eq([]) }
    end
  end

  describe '#invite?' do
    let(:dossier) { create :dossier }
    let(:user) { dossier.user }

    subject { user.invite? dossier.id }

    context 'when user is invite at the dossier' do
      before do
        create :invite, dossier_id: dossier.id, user: user
      end

      it { is_expected.to be_truthy }
    end

    context 'when user is not invite at the dossier' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#owns_or_invite?' do
    let(:owner) { create(:user) }
    let(:dossier) { create(:dossier, user: owner) }
    let(:invite_user) { create(:user) }
    let(:invite_gestionnaire) { create(:user) }

    subject { user.owns_or_invite?(dossier) }

    context 'when user is owner' do
      let(:user) { owner }

      it { is_expected.to be_truthy }
    end

    context 'when user was invited by user' do
      before do
        create(:invite, dossier: dossier, user: invite_user)
      end

      let(:user) { invite_user }

      it { is_expected.to be_truthy }
    end

    context 'when user is quidam' do
      let(:user) { create(:user) }

      it { is_expected.to be_falsey }
    end
  end

  context 'unified login' do
    it 'syncs credentials to associated gestionnaire' do
      user = create(:user)
      gestionnaire = create(:gestionnaire, email: user.email)

      user.update(email: 'whoami@plop.com', password: 'démarches-simplifiées2')

      gestionnaire.reload
      expect(gestionnaire.email).to eq('whoami@plop.com')
      expect(gestionnaire.valid_password?('démarches-simplifiées2')).to be(true)
    end

    it 'syncs credentials to associated administrateur' do
      user = create(:user)
      admin = create(:administrateur, email: user.email)

      user.update(email: 'whoami@plop.com', password: 'démarches-simplifiées2')

      admin.reload
      expect(admin.email).to eq('whoami@plop.com')
      expect(admin.valid_password?('démarches-simplifiées2')).to be(true)
    end
  end
end
