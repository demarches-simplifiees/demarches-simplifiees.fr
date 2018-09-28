require 'spec_helper'

describe User, type: :model do
  describe '#after_confirmation' do
    let(:email) { 'mail@beta.gouv.fr' }
    let!(:invite)  { create(:invite, email: email) }
    let!(:invite2) { create(:invite, email: email) }
    let(:user) do
      create(:user,
        email: email,
        password: 'a good password',
        confirmation_token: '123',
        confirmed_at: nil)
    end

    it 'when confirming a user, it links the pending invitations to this user' do
      expect(user.invites.size).to eq(0)
      user.confirm
      expect(user.reload.invites.size).to eq(2)
    end
  end

  describe '#find_for_france_connect' do
    let(:siret) { '00000000000000' }
    context 'when user exist' do
      let!(:user) { create(:user) }
      subject { described_class.find_for_france_connect(user.email, siret) }
      it 'retrieves user' do
        expect(subject).to eq(user)
      end
      it 'saves siret in user' do
        expect(subject.siret).to eq(siret)
      end
      it 'does not create new user' do
        expect { subject }.not_to change(User, :count)
      end
    end
    context 'when user does not exist' do
      let(:email) { 'super-m@n.com' }
      subject { described_class.find_for_france_connect(email, siret) }
      it 'returns user' do
        expect(subject).to be_an_instance_of(User)
      end
      it 'creates new user' do
        expect { subject }.to change(User, :count).by(1)
      end
      it 'saves siret' do
        expect(subject.siret).to eq(siret)
      end
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
        create(:invite, dossier: dossier, user: invite_user, type: 'InviteUser')
      end

      let(:user) { invite_user }

      it { is_expected.to be_falsy }
    end

    context 'when user is quidam' do
      let(:user) { create(:user) }

      it { is_expected.to be_falsey }
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
        create(:invite, dossier: dossier, user: invite_user, type: 'InviteUser')
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

      user.update(email: 'whoami@plop.com', password: 'super secret')

      gestionnaire.reload
      expect(gestionnaire.email).to eq('whoami@plop.com')
      expect(gestionnaire.valid_password?('super secret')).to be(true)
    end

    it 'syncs credentials to associated administrateur' do
      user = create(:user)
      admin = create(:administrateur, email: user.email)

      user.update(email: 'whoami@plop.com', password: 'super secret')

      admin.reload
      expect(admin.email).to eq('whoami@plop.com')
      expect(admin.valid_password?('super secret')).to be(true)
    end
  end
end
