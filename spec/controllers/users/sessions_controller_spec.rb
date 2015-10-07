require 'spec_helper'

describe Users::SessionsController, type: :controller do

  describe '.create' do
    let(:user) { create(:user, login_with_france_connect: true) }

    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      post :create, user: { email: user.email, password: user.password }
    end

    it 'login_with_france_connect current_user attribut is false' do
      user.reload
      expect(user.login_with_france_connect).to be_falsey
    end
  end
end