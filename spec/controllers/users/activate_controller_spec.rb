describe Users::ActivateController, type: :controller do
  describe '#new' do
    let(:user) { create(:user) }
    let(:token) { user.send(:set_reset_password_token) }

    before { allow(controller).to receive(:trust_device) }

    context 'when the token is ok' do
      before { get :new, params: { token: token } }

      it { expect(controller).to have_received(:trust_device) }
    end

    context 'when the token is bad' do
      before { get :new, params: { token: 'bad' } }

      it { expect(controller).not_to have_received(:trust_device) }
    end
  end

  describe '#create' do
    let!(:user) { create(:user) }
    let(:token) { user.send(:set_reset_password_token) }
    let(:password) { 'another-password-ok?' }

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
