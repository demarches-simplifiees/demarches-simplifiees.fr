require 'spec_helper'

describe FranceConnectController, type: :controller do

  describe '.login' do
    it 'redirect to france connect serveur' do
      get :login
      expect(response.status).to eq(302)
    end
  end

  describe '.callback' do
    context 'when param code is missing' do
      it 'redirect to login page' do
        get :callback
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when params code is present' do
      let(:code) { 'plop' }

      context 'when code is correct' do
        let(:email) { 'patator@cake.com' }
        let(:current_user) { User.find_by_email(email) }

        before do
          allow(FranceConnectService).to receive(:retrieve_user_informations).and_return(Hashie::Mash.new(email: email))
          get :callback, code: code
        end

        it 'login_with_france_connect user attribut is true' do
          expect(current_user.login_with_france_connect).to be_truthy
        end

        it 'redirect to dossiers list' do
          get :callback, code: code
          expect(response).to redirect_to(controller: 'users/dossiers', action: :index)
        end
      end

      context 'wen code is not correct' do
        before do
          allow(FranceConnectService).to receive(:retrieve_user_informations) { raise Rack::OAuth2::Client::Error.new(500, error: 'Unknown') }
          get :callback, code: code
        end

        it 'redirect to login page' do
          expect(response).to redirect_to(new_user_session_path)
        end

        it 'display error message' do
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end

