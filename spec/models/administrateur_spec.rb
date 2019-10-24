require 'spec_helper'

describe Administrateur, type: :model do
  let(:administration) { create(:administration) }

  describe 'assocations' do
    it { is_expected.to have_and_belong_to_many(:instructeurs) }
    it { is_expected.to have_many(:procedures) }
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

  # describe '#password_complexity' do
  #   let(:email) { 'mail@beta.gouv.fr' }
  #   let(:passwords) { ['pass', '12pass23', 'démarches ', 'démarches-simple', 'démarches-simplifiées-pwd'] }
  #   let(:administrateur) { build(:administrateur, email: email, password: password) }
  #   let(:min_complexity) { PASSWORD_COMPLEXITY_FOR_ADMIN }

  #   subject do
  #     administrateur.save
  #     administrateur.errors.full_messages
  #   end

  #   context 'when password is too short' do
  #     let(:password) { 's' * (PASSWORD_MIN_LENGTH - 1) }

  #     it { expect(subject).to eq(["Le mot de passe est trop court"]) }
  #   end

  #   context 'when password is too simple' do
  #     let(:password) { passwords[min_complexity - 1] }

  #     it { expect(subject).to eq(["Le mot de passe n'est pas assez complexe"]) }
  #   end

  #   context 'when password is acceptable' do
  #     let(:password) { passwords[min_complexity] }

  #     it { expect(subject).to eq([]) }
  #   end
  # end

  describe '#active?' do
    let!(:administrateur) { create(:administrateur) }

    subject { administrateur.active? }

    context 'when the user has never signed in' do
      before { administrateur.user.update(last_sign_in_at: nil) }

      it { is_expected.to be false }
    end

    context 'when the user has already signed in' do
      before { administrateur.user.update(last_sign_in_at: Time.zone.now) }

      it { is_expected.to be true }
    end
  end
end
