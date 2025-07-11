# frozen_string_literal: true

RSpec.describe TrustedDeviceToken, type: :model do
  describe '.expiring_in_one_week' do
    let!(:token_to_notify) do
      create(:trusted_device_token,
        activated_at: (TrustedDeviceConcern::TRUSTED_DEVICE_PERIOD - 5.days).ago,
        renewal_notified_at: nil)
    end
    let!(:token_already_notified) do
      create(:trusted_device_token,
        activated_at: (TrustedDeviceConcern::TRUSTED_DEVICE_PERIOD - 1.day).ago,
        renewal_notified_at: Time.zone.now)
    end
    let!(:token_not_expiring) do
      create(:trusted_device_token,
        activated_at: 2.weeks.ago,
        renewal_notified_at: nil)
    end

    it 'returns only tokens expiring in one week and not yet notified' do
      expect(described_class.expiring_in_one_week).to contain_exactly(token_to_notify)
    end
  end

  describe '#token_valid?' do
    let(:token) { create(:trusted_device_token) }

    context 'when the token is create after login_token_validity' do
      it { expect(token.token_valid?).to be true }
    end

    context 'when the token is create before login_token_validity' do
      before { token.update(created_at: (TrustedDeviceToken::LOGIN_TOKEN_VALIDITY + 1.minute).ago) }

      it { expect(token.token_valid?).to be false }
    end
  end

  describe '#token_young?' do
    let(:token) { create(:trusted_device_token) }

    context 'when the token is create after login_token_youth' do
      it { expect(token.token_young?).to be true }
    end

    context 'when the token is create before login_token_youth' do
      before { token.update(created_at: (TrustedDeviceToken::LOGIN_TOKEN_YOUTH + 1.minute).ago) }

      it { expect(token.token_young?).to be false }
    end
  end
end
