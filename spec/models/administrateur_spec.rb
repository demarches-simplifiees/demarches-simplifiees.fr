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

  describe '#feature_enabled?' do
    let(:administrateur) { create(:administrateur) }

    before do
      administrateur.enable_feature(:test_a)
    end

    it { expect(administrateur.feature_enabled?(:test_b)).to be_falsey }
    it { expect(administrateur.feature_enabled?(:test_a)).to be_truthy }
  end
end
