describe Users::ConfirmationsController, type: :controller do
  let!(:user) { create(:user, :unconfirmed) }
  let(:confirmation_token) { user.confirmation_token }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#show' do
    context 'when confirming within the auto-sign-in delay' do
      before do
        Timecop.travel(1.hour.from_now) {
          get :show, params: { confirmation_token: confirmation_token }
        }
      end

      it 'confirms the user' do
        expect(user.reload).to be_confirmed
      end

      it 'signs in the user after confirming its token' do
        expect(controller.current_user).to eq(user)
        expect(controller.current_instructeur).to be(nil)
        expect(controller.current_administrateur).to be(nil)
      end

      it 'redirects the user to the root page' do
        # NB: the root page may redirect the user again to the stored procedure path
        expect(controller).to redirect_to(root_path)
      end
    end

    context 'when the auto-sign-in delay has expired' do
      before do
        Timecop.travel(3.hours.from_now) {
          get :show, params: { confirmation_token: confirmation_token }
        }
      end

      it 'confirms the user' do
        expect(user.reload).to be_confirmed
      end

      it 'doesn’t sign in the user' do
        expect(subject.current_user).to be(nil)
        expect(subject.current_instructeur).to be(nil)
        expect(subject.current_administrateur).to be(nil)
      end

      it 'redirects the user to the sign-in path' do
        expect(subject).to redirect_to(new_user_session_path)
      end
    end

    context 'when account was already confirmed long time ago' do
      let!(:user) { create(:user, confirmed_at: 3.hours.ago, confirmation_sent_at: 4.hours.ago, confirmation_token: "mytoken") }
      render_views

      subject do
        get :show, params: { confirmation_token: confirmation_token }
      end

      it 'redirect and does not expose the email' do
        expect(user).to be_confirmed
        expect(subject).to redirect_to(new_user_session_path)
        expect(subject.body).not_to include(user.email)
        expect(flash.notice).to include("Votre compte a déjà été activé")
      end
    end
  end
end
