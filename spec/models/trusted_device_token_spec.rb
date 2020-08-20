RSpec.describe TrustedDeviceToken, type: :model do
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
