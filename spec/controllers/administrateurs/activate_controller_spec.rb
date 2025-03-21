describe Administrateurs::ActivateController, type: :controller do
  describe '#new' do
    let(:admin) { administrateurs(:default_admin) }
    let(:token) { admin.user.send(:set_reset_password_token) }

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
    let!(:administrateur) { administrateurs(:default_admin) }
    let(:token) { administrateur.user.send(:set_reset_password_token) }
    let(:password) { 'Another-password-ok!@#123?' }

    before { post :create, params: { administrateur: { reset_password_token: token, password: password } } }

    context 'when the token is ok' do
      it { expect(administrateur.user.reload.valid_password?(password)).to be true }
      it { expect(response).to redirect_to(admin_procedures_path) }
    end

    context 'when the password is not strong' do
      let(:password) { 'another-password-ok?' }

      it { expect(administrateur.user.reload.valid_password?(password)).to be false }
      it { expect(response).to redirect_to(admin_activate_path(token: token)) }
    end

    context 'when the token is bad' do
      let(:token) { 'bad' }

      it { expect(administrateur.user.reload.valid_password?(password)).to be false }
      it { expect(response).to redirect_to(admin_activate_path(token: token)) }
    end
  end
end
