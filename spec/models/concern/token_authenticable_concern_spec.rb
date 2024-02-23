# frozen_string_literal: true

RSpec.describe TokenAuthenticableConcern, type: :model do
    let(:user) { create(:user, sign_in_secret: secret) }
    let(:secret) { nil }

    describe '#authenticable_token' do
      it 'generates a valid cross domain token' do
        token = user.authenticable_token

        expect(user.sign_in_secret).not_to be_nil

        decoded_payload = User.token_authenticable_verifier.verify(token)
        expect(decoded_payload[:user_id]).to eq(user.id)
        expect(decoded_payload[:sign_in_secret]).to eq(user.sign_in_secret)
      end

      context 'with an existing secret' do
        let(:secret) { "abc" }

        it 'reuses the same secret' do
          expect { user.authenticable_token }.not_to change(user, :sign_in_secret)
        end
      end
    end

    describe '#reset_sign_in_secret!' do
      let(:secret) { "abc" }

      it do
        expect { user.reset_sign_in_secret! }.to change(user, :sign_in_secret).from("abc").to(String)
      end
    end

    describe '#clear_sign_in_secret!' do
      let(:secret) { "abc" }

      it do
        expect { user.clear_sign_in_secret! }.to change(user, :sign_in_secret).to(nil)
      end
    end

    describe '.find_by_authenticable_token' do
      it 'finds the user with a valid token' do
        token = user.authenticable_token
        travel_to 1.minute.from_now

        expect(User.find_by_authenticable_token(token)).to eq(user)
      end

      it 'ignore expired tokens' do
        token = user.authenticable_token
        travel_to 2.hours.from_now
        expect(User.find_by_authenticable_token(token)).to be_nil
      end

      it 'returns nil with an invalid token' do
        expect(User.find_by_authenticable_token('invalid.token')).to be_nil
      end
    end
  end
