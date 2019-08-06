require "spec_helper"

describe Instructeurs::PasswordsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:instructeur]
  end

  describe "update" do
    context "unified login" do
      let(:user) { create(:user, email: 'unique@plop.com', password: 'démarches-simplifiées-pwd') }
      let(:administrateur) { create(:administrateur, email: 'unique@plop.com', password: 'démarches-simplifiées-pwd') }
      let(:instructeur) { administrateur.instructeur }

      before do
        @token = instructeur.send(:set_reset_password_token)
        user # make sure it's created
        administrateur # make sure it's created
      end

      it "also signs user in" do
        put :update, params: {
          instructeur: {
            reset_password_token: @token,
            password: "démarches-simplifiées-pwd",
            password_confirmation: "démarches-simplifiées-pwd"
          }
        }
        expect(subject.current_instructeur).to eq(instructeur)
        expect(subject.current_user).to eq(user)
      end

      it "also signs administrateur in" do
        put :update, params: {
          instructeur: {
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
