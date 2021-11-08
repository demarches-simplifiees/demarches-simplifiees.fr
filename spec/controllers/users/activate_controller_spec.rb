describe Users::ActivateController, type: :controller do
  describe '#new' do
    before do
      allow(controller).to receive(:trust_device)
      get :new, params: { token: token }
    end

    context 'when the token is ok' do
      let(:user) { create(:user) }
      let(:token) { user.send(:set_reset_password_token) }

      context 'for a simple user' do
        it do
          expect(controller).to have_received(:trust_device)
          expect(assigns(:min_complexity)).to eq(PASSWORD_COMPLEXITY_FOR_USER)
        end
      end

      context 'for an instructeur' do
        let(:user) { create(:instructeur).user }
        it { expect(assigns(:min_complexity)).to eq(PASSWORD_COMPLEXITY_FOR_INSTRUCTEUR) }
      end

      context 'for an administrateur' do
        let(:user) { create(:administrateur).user }
        it { expect(assigns(:min_complexity)).to eq(PASSWORD_COMPLEXITY_FOR_ADMIN) }
      end
    end

    context 'when the token is bad' do
      let(:user) { create(:user) }
      let(:token) { 'bad' }
      it { expect(controller).not_to have_received(:trust_device) }
    end
  end

  describe '#create' do
    let!(:instructeur) { create(:instructeur) }
    let!(:user) { instructeur.user }
    let(:token) { user.send(:set_reset_password_token) }
    let(:password) { TEST_PASSWORD }

    before { post :create, params: { user: { reset_password_token: token, password: password } } }

    context 'when the token is ok' do
      it { expect(user.reload.valid_password?(password)).to be true }
      it { expect(response).to redirect_to(instructeur_procedures_path) }
    end

    context 'when the token is bad' do
      let(:token) { 'bad' }

      it { expect(user.reload.valid_password?(password)).to be false }
      it { expect(response).to redirect_to(users_activate_path(token: token)) }
    end
  end
end
