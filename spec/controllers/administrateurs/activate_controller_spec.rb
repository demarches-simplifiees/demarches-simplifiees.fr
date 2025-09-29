# frozen_string_literal: true

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
      it do
        admin_user = administrateur.user.reload
        expect(admin_user.valid_password?(password)).to be true
        expect(admin_user.email_verified_at).to be_present
        expect(response).to redirect_to(admin_procedures_path)
      end
    end

    context 'when the password is not strong' do
      let(:password) { 'password-ok?' }

      it do
        expect(administrateur.user.reload.valid_password?(password)).to be false
        expect(response).to redirect_to(admin_activate_path(token: token))
      end
    end

    context 'when the token is bad' do
      let(:token) { 'bad' }

      it do
        expect(administrateur.user.reload.valid_password?(password)).to be false
        expect(response).to redirect_to(admin_activate_path(token: token))
      end
    end
  end
end
