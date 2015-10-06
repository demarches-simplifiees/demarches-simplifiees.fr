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
      before do
        get :callback, code: code
      end

      context 'when code is correct' do
        before do
          allow(FranceConnectService).to receive(:retrieve_user_informations).and_return(Hashie::Mash.new(email: 'patator@cake.com'))
        end
        it 'redirect to dossiers list' do
          expect(response).to redirect_to(controller: 'users/dossiers', action: :index)
        end
      end

      context 'wen code is not correct' do
        before do
          allow(FranceConnectService).to receive(:retrieve_user_informations).and_raise(Rack::OAuth2::Client::Error)
        end

        it 'redirect to login page' do
          expect(response).to redirect_to(controller: 'users/sign_in', action: :index)
        end

        it 'flash message error connexion with France Connect' do

        end
      end
    end
  end
end

