RSpec.describe ApplicationController::AuthenticateByToken, type: :controller do
  controller do
    include ApplicationController::AuthenticateByToken

    def index
      render plain: "Hello, world!"
    end
  end

  before do
    Rails.application.routes.draw do
      get '/authenticated' => 'anonymous#index'
    end

    allow(controller).to receive(:sign_in).with(user)
  end

  describe '#authentication_user! with token' do
    let(:user) { create(:user) }

    subject { get :index, params: { authenticable_token: token } }

    context "when authenticable_token is present in params" do
      let(:token) { user.authenticable_token }

      it "authenticates the user with the token" do
        subject
        expect(controller).to have_received(:sign_in).with(user)
        expect(user.reload.sign_in_secret).to be_nil
        expect(flash).to be_empty
        expect(response).to redirect_to("/authenticated")
      end

      context "when token has expired" do
        let(:token) { travel_to(20.minutes.ago) { user.authenticable_token } }

        it "does not authenticate the user" do
          subject
          expect(controller).not_to have_received(:sign_in)
          expect(response).to redirect_to("/authenticated")
        end
      end

      context "when token is invalid" do
        let(:token) { "invalid_token" }

        it "redirects without signing in the user" do
          subject
          expect(controller).not_to have_received(:sign_in)
          expect(response).to redirect_to("/authenticated")
        end
      end
    end

    context "when authenticable_token is not present" do
      it "calls the original Devise authenticate_user!" do
        get :index
        expect(controller).not_to have_received(:sign_in)
      end
    end
  end
end
