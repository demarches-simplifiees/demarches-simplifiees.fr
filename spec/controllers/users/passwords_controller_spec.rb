describe Users::PasswordsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "update" do
    context "unified login" do
      let(:administrateur) { create(:administrateur, email: 'unique@plop.com', password: 'mot de passe complexe') }
      let(:user) { administrateur.instructeur.user }

      before do
        @token = user.send(:set_reset_password_token)
        administrateur # make sure it's created
      end

      it "also signs instructeur in" do
        put :update, params: {
          user: {
            reset_password_token: @token,
            password: "mot de passe super secret",
            password_confirmation: "mot de passe super secret"
          }
        }
        expect(subject.current_user).to eq(user)
        expect(subject.current_instructeur.email).to eq(administrateur.email)
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

  describe '#edit' do
    before do
      @token = user.send(:set_reset_password_token)
      get :edit, params: { reset_password_token: @token }
    end

    context "for simple user" do
      let(:user) { create(:user, email: 'unique@plop.com', password: 'mot de passe complexe') }

      it "should allows user level complexity for password" do
        expect(assigns(:test_password_strength)).to eq(test_password_strength_path(PASSWORD_COMPLEXITY_FOR_USER))
      end
    end

    context "for instructeur" do
      let(:instructeur) { create(:instructeur, email: 'unique@plop.com', password: 'mot de passe complexe') }
      let(:user) { instructeur.user }

      it "should allows instructeur level complexity for password" do
        expect(assigns(:test_password_strength)).to eq(test_password_strength_path(PASSWORD_COMPLEXITY_FOR_INSTRUCTEUR))
      end
    end

    context "for administrateur" do
      let(:administrateur) { create(:administrateur, email: 'unique@plop.com', password: 'mot de passe complexe') }
      let(:user) { administrateur.instructeur.user }

      it "should allows administrateur level complexity for password" do
        expect(assigns(:test_password_strength)).to eq(test_password_strength_path(PASSWORD_COMPLEXITY_FOR_ADMIN))
      end
    end
  end
end
