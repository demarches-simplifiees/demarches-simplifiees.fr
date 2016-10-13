require "spec_helper"

describe Users::PasswordsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "update" do
    context "when associated gestionnaire" do
      let(:user) { create(:user, email: 'unique@plop.com', password: 'password') }
      let(:gestionnaire) { create(:gestionnaire, email: 'unique@plop.com', password: 'password') }

      before do
        @token = user.send(:set_reset_password_token)
        gestionnaire # make sure it's created
      end

      it "also signs gestionnaire in" do
        put :update, user: {
          reset_password_token: @token,
          password: "supersecret",
          password_confirmation: "supersecret",
        }
        expect(subject.current_user).to eq(user)
        expect(subject.current_gestionnaire).to eq(gestionnaire)
      end
    end
  end
end
