require 'spec_helper'

describe Administrateur, type: :model do
  describe 'assocations' do
    it { is_expected.to have_and_belong_to_many(:gestionnaires) }
    it { is_expected.to have_many(:procedures) }
  end

  describe 'after_save' do
    subject { described_class.new(email: 'toto@tps.com', password: 'password') }
    before do
      subject.save
    end
    it { expect(subject.api_token).not_to be_blank }
  end

  describe 'generate_api_token' do
    let(:token) { 'bullshit' }
    let(:new_token) { 'pocket_master' }
    let!(:admin_1) { create(:administrateur, email: 'toto@tps.com', password: 'password', api_token: token) }
    before do
      allow(SecureRandom).to receive(:hex).and_return(token, new_token)
      admin_1.renew_api_token
    end
    it 'generate a token who does not already exist' do
      expect(admin_1.api_token).to eq(new_token)
    end
  end

  context 'unified login' do
    it 'syncs credentials to associated user' do
      administrateur = create(:administrateur)
      user = create(:user, email: administrateur.email)

      administrateur.update(email: 'whoami@plop.com', password: 'super secret')

      user.reload
      expect(user.email).to eq('whoami@plop.com')
      expect(user.valid_password?('super secret')).to be(true)
    end

    it 'syncs credentials to associated administrateur' do
      administrateur = create(:administrateur)
      gestionnaire = create(:gestionnaire, email: administrateur.email)

      administrateur.update(email: 'whoami@plop.com', password: 'super secret')

      gestionnaire.reload
      expect(gestionnaire.email).to eq('whoami@plop.com')
      expect(gestionnaire.valid_password?('super secret')).to be(true)
    end
  end

  describe '#find_inactive_by_token' do
    let(:administrateur) { create(:administration).invite_admin('paul@tps.fr') }
    let(:reset_password_token) { administrateur.invite! }

    it { expect(Administrateur.find_inactive_by_token(reset_password_token)).not_to be_nil }
  end

  describe '#reset_password' do
    let(:administrateur) { create(:administration).invite_admin('paul@tps.fr') }
    let(:reset_password_token) { administrateur.invite! }

    it { expect(Administrateur.reset_password(reset_password_token, '12345678').errors).to be_empty }
    it { expect(Administrateur.reset_password('123', '12345678').errors).not_to be_empty }
    it { expect(Administrateur.reset_password(reset_password_token, '').errors).not_to be_empty }
  end

  describe '#feature_enabled?' do
    let(:administrateur) { create(:administrateur) }

    before do
      administrateur.enable_feature(:champ_pj)
    end

    it { expect(administrateur.feature_enabled?(:champ_siret)).to be_falsey }
    it { expect(administrateur.feature_enabled?(:champ_pj)).to be_truthy }
  end
end
