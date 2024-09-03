# frozen_string_literal: true

RSpec.describe ApplicationController::LongLivedAuthenticityToken, type: :controller do
  controller(ActionController::Base) do
    include ApplicationController::LongLivedAuthenticityToken
  end

  describe '#real_csrf_token' do
    subject { controller.send(:real_csrf_token, session) }

    context 'when the long-lived cookie has a token' do
      before do
        token = controller.send(:generate_csrf_token)

        @controller.send(:cookies).signed[ApplicationController::LongLivedAuthenticityToken::COOKIE_NAME] = {
          value: token,
          expires: 1.year.from_now,
          httponly: true
        }

        @decrypted_token = controller.send(:decode_csrf_token, token)
      end

      it 'returns the decoded token' do
        expect(subject).to eq @decrypted_token
      end
    end

    context 'when the long-lived cookie is empty, but the session has a token' do
      before do
        token = controller.send(:generate_csrf_token)

        session[:_csrf_token] = token

        @decrypted_token = controller.send(:decode_csrf_token, token)
      end

      it 'returns the decoded token' do
        expect(subject).to eq @decrypted_token
      end
    end

    context 'when no token is present' do
      it 'generates a new token' do
        expect(subject).to be_present
      end

      it 'stores the new token in the long-lived cookie' do
        subject
        expect(controller.send(:cookies).signed[ApplicationController::LongLivedAuthenticityToken::COOKIE_NAME]).to be_present
      end

      it 'stores the new token in the session' do
        subject
        expect(controller.session[:_csrf_token]).to be_present
      end
    end
  end
end

RSpec.describe "CSRF cleanup", type: :request do
  describe 'csrf_cleaner hook', :allow_forgery_protection do
    let(:user) { create(:user, password: password) }
    let(:password) { SECURE_PASSWORD }

    it 'refreshes the long-lived cookie after authentication' do
      get new_user_session_path
      cookie_token = long_lived_cookie

      # The token in the long-lived cookie doesn't change between requests
      # (This is not strictly needed, but ensures we read the signed cookie properly.)
      get new_user_session_path

      expect(long_lived_cookie).to be_present
      expect(long_lived_cookie).to eq cookie_token

      # The token in the long-lived cookie is refreshed after authentication
      post user_session_path,
           params: { user: { email: user.email, password: password } },
           headers: { 'HTTP_X_CSRF_TOKEN' => header_authenticity_token(response) }
      follow_redirect!
      follow_redirect! # After sign-in, we are redirected twice

      expect(response).to have_http_status(200)
      expect(long_lived_cookie).to be_present
      expect(long_lived_cookie).not_to eq cookie_token
    end
  end

  private

  def header_authenticity_token(response)
    regex = /meta name="csrf-token" content="(?<token>.+)"/
    parts = response.body.match(regex)
    parts['token'] if parts
  end

  def long_lived_cookie
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    jar.signed[ApplicationController::LongLivedAuthenticityToken::COOKIE_NAME.to_s]
  end
end
