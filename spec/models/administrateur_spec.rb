require 'spec_helper'

describe Administrateur, type: :model do
  describe 'database column' do
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
    it { is_expected.to have_db_column(:api_token) }
  end

  describe 'assocations' do
    it { is_expected.to have_many(:gestionnaires) }
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
    let!(:admin_1) { create(:administrateur, email: 'toto@tps.com', password: 'password', api_token: token)  }
    before do
      allow(SecureRandom).to receive(:hex).and_return(token, new_token)
      admin_1.renew_api_token
    end
    it 'generate a token who does not already exist' do
      expect(admin_1.api_token).to eq(new_token)
    end
  end
end
