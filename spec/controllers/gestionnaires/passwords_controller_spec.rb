require "spec_helper"

describe Gestionnaires::PasswordsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:gestionnaire]
  end

  describe "update" do
    context "unified login" do
      let(:user) { create(:user, email: 'unique@plop.com', password: 'démarches-simplifiées-pwd') }
      let(:administrateur) { create(:administrateur, email: 'unique@plop.com', password: 'démarches-simplifiées-pwd') }
      let(:gestionnaire) { administrateur.gestionnaire }

      before do
        @token = gestionnaire.send(:set_reset_password_token)
        user # make sure it's created
        administrateur # make sure it's created
      end

      it "also signs user in" do
        put :update, params: {
          gestionnaire: {
            reset_password_token: @token,
            password: "démarches-simplifiées-pwd",
            password_confirmation: "démarches-simplifiées-pwd"
          }
        }
        expect(subject.current_gestionnaire).to eq(gestionnaire)
        expect(subject.current_user).to eq(user)
      end

      it "also signs administrateur in" do
        put :update, params: {
          gestionnaire: {
            reset_password_token: @token,
            password: "démarches-simplifiées-pwd",
            password_confirmation: "démarches-simplifiées-pwd"
          }
        }
        expect(subject.current_administrateur).to eq(administrateur)
        expect(subject.current_user).to eq(user)
      end
    end
  end
end
