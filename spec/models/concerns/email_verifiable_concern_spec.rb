# frozen_string_literal: true

describe EmailVerifiableConcern do
  let(:user) { create(:user) }

  describe '#verify_email_token' do
    it 'generates a signed global ID token for the user' do
      token = user.verify_email_token
      expect(token).to be_a(String)

      # Verify that the token can be located and is valid
      located_user = GlobalID::Locator.locate_signed(token, for: 'verify_email')
      expect(located_user).to eq(user)
    end
  end

  describe '.with_verify_email_token' do
    context 'with a valid token' do
      it 'finds the user by the verification token' do
        token = user.verify_email_token
        found_user = User.with_verify_email_token(token)

        expect(found_user).to eq(user)
      end
    end

    context 'with an invalid token' do
      it 'returns nil for an invalid token' do
        found_user = User.with_verify_email_token('invalid_token')
        expect(found_user).to be_nil
      end
    end
  end
end
