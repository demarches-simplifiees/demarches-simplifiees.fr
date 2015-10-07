require 'spec_helper'

describe Users::SessionsController, type: :controller do
  let(:login_with_france_connect) { true }
  let(:user) { create(:user, login_with_france_connect: login_with_france_connect) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '.create' do
    before do
      post :create, user: {email: user.email, password: user.password}
    end

    it 'login_with_france_connect current_user attribut is false' do
      user.reload
      expect(user.login_with_france_connect).to be_falsey
    end
  end

  describe '.destroy' do
    before do
      sign_in user
      delete :destroy
    end

    it 'user is sign out' do
      expect(subject.current_user).to be_nil
    end

    it 'login_with_france_connect current_user attribut is false' do
      user.reload
      expect(user.login_with_france_connect).to be_falsey
    end

    context 'when user is connect with france connect' do
      it 'redirect to france connect logout page' do
        expect(response).to redirect_to(FRANCE_CONNECT.logout_endpoint)
      end
    end

    context 'when user is not connect with france connect' do
      let(:login_with_france_connect) { false }
      
      it 'redirect to root page' do
        expect(response).to redirect_to(root_path)
      end
    end
  end
end