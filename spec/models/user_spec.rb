require 'rails_helper'

describe User, type: :model do
  describe 'database columns' do
    it { is_expected.to have_db_column(:email) }
    it { is_expected.to have_db_column(:encrypted_password) }
    it { is_expected.to have_db_column(:reset_password_token) }
    it { is_expected.to have_db_column(:reset_password_sent_at) }
    it { is_expected.to have_db_column(:remember_created_at) }
    it { is_expected.to have_db_column(:sign_in_count) }
    it { is_expected.to have_db_column(:current_sign_in_at) }
    it { is_expected.to have_db_column(:last_sign_in_at) }
    it { is_expected.to have_db_column(:current_sign_in_ip) }
    it { is_expected.to have_db_column(:last_sign_in_ip) }
    it { is_expected.to have_db_column(:created_at) }
    it { is_expected.to have_db_column(:updated_at) }
    it { is_expected.to have_db_column(:siret) }
    it { is_expected.to have_db_column(:loged_in_with_france_connect) }

  end
  describe 'associations' do
    it { is_expected.to have_many(:dossiers) }
    it { is_expected.to have_many(:invites) }
    it { is_expected.to have_many(:piece_justificative) }
    it { is_expected.to have_many(:cerfa) }
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

  context 'unified login' do
    before { allow(Features).to receive(:unified_login).and_return(true) }

    it 'syncs credentials to associated gestionnaire' do
      user = create(:user)
      gestionnaire = create(:gestionnaire, email: user.email)

      user.update_attributes(email: 'whoami@plop.com', password: 'super secret')

      gestionnaire.reload
      expect(gestionnaire.email).to eq('whoami@plop.com')
      expect(gestionnaire.valid_password?('super secret')).to be(true)
    end
  end
end
