require 'spec_helper'

describe Administrateur, type: :model do
  let(:administration) { create(:administration) }

  describe 'assocations' do
    it { is_expected.to have_and_belong_to_many(:gestionnaires) }
    it { is_expected.to have_many(:procedures) }
  end

  context 'unified login' do
    it 'syncs credentials to associated user' do
      administrateur = create(:administrateur)
      user = create(:user, email: administrateur.email)

      administrateur.update(email: 'whoami@plop.com', password: 'voilà un super mdp')

      user.reload
      expect(user.email).to eq('whoami@plop.com')
      expect(user.valid_password?('voilà un super mdp')).to be(true)
    end

    it 'syncs credentials to associated administrateur' do
      administrateur = create(:administrateur)
      gestionnaire = administrateur.gestionnaire

      administrateur.update(email: 'whoami@plop.com', password: 'et encore un autre mdp')

      gestionnaire.reload
      expect(gestionnaire.email).to eq('whoami@plop.com')
      expect(gestionnaire.valid_password?('et encore un autre mdp')).to be(true)
    end
  end

  describe "#renew_api_token" do
    let!(:administrateur) { create(:administrateur) }
    let!(:token) { administrateur.renew_api_token }

    it { expect(BCrypt::Password.new(administrateur.encrypted_token)).to eq(token) }

    context 'when it s called twice' do
      let!(:new_token) { administrateur.renew_api_token }

      it { expect(new_token).not_to eq(token) }
    end
  end

  describe '#find_inactive_by_token' do
    let(:administrateur) { create(:administration).invite_admin('paul@tps.fr') }
    let(:reset_password_token) { administrateur.invite!(administration.id) }

    it { expect(Administrateur.find_inactive_by_token(reset_password_token)).not_to be_nil }
  end

  describe '#reset_password' do
    let(:administrateur) { create(:administration).invite_admin('paul@tps.fr') }
    let(:reset_password_token) { administrateur.invite!(administration.id) }

    it { expect(Administrateur.reset_password(reset_password_token, "j'aime manger des radis").errors).to be_empty }
    it { expect(Administrateur.reset_password('123', "j'aime manger des radis").errors).not_to be_empty }
    it { expect(Administrateur.reset_password(reset_password_token, '').errors).not_to be_empty }
  end

  describe '#feature_enabled?' do
    let(:administrateur) { create(:administrateur) }

    before do
      administrateur.enable_feature(:test_a)
    end

    it { expect(administrateur.feature_enabled?(:test_b)).to be_falsey }
    it { expect(administrateur.feature_enabled?(:test_a)).to be_truthy }
  end

  describe '#password_complexity' do
    let(:email) { 'mail@beta.gouv.fr' }
    let(:passwords) { ['pass', '12pass23', 'démarches ', 'démarches-simple', 'démarches-simplifiées pwd'] }
    let(:administrateur) { build(:administrateur, email: email, password: password) }
    let(:min_complexity) { PASSWORD_COMPLEXITY_FOR_ADMIN }

    subject do
      administrateur.save
      administrateur.errors.full_messages
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
end
