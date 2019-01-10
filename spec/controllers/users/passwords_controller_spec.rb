require "spec_helper"

describe Users::PasswordsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "update" do
    context "unified login" do
      let(:user) { create(:user, email: 'unique@plop.com', password: 'mot de passe complexe') }
      let(:administrateur) { create(:administrateur, email: 'unique@plop.com', password: 'mot de passe complexe') }

      before do
        @token = user.send(:set_reset_password_token)
        administrateur # make sure it's created
      end

      it "also signs gestionnaire in" do
        put :update, params: {
          user: {
            reset_password_token: @token,
            password: "mot de passe super secret",
            password_confirmation: "mot de passe super secret"
          }
        }
        expect(subject.current_user).to eq(user)
        expect(subject.current_gestionnaire.email).to eq(administrateur.email)
      end

      it "also signs administrateur in" do
        put :update, params: {
          user: {
            reset_password_token: @token,
            password: "mot de passe super secret",
            password_confirmation: "mot de passe super secret"
          }
        }
        expect(subject.current_user).to eq(user)
        expect(subject.current_administrateur).to eq(administrateur)
      end
    end
  end
end
