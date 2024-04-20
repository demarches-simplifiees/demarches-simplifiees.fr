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

  describe '#reset_link_sent' do
    let(:email) { 'test@example.com' }

    it 'displays the page' do
      signed_email = controller.message_verifier.generate(email, purpose: :reset_password)

      get 'reset_link_sent', params: { email: signed_email }

      expect(response).to have_http_status(:ok)
      expect(response).to render_template('reset_link_sent')
      expect(assigns(:email)).to eq email
    end

    context 'when signed email is invalid' do
      it "does not fail" do
        get 'reset_link_sent', params: { email: "invalid.message" }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template('reset_link_sent')
        expect(assigns(:email)).to be_nil
      end
    end
  end
end
