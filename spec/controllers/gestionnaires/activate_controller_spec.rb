# frozen_string_literal: true

describe Gestionnaires::ActivateController, type: :controller do
  describe '#new' do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:token) { gestionnaire.user.send(:set_reset_password_token) }

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
    let!(:gestionnaire) { create(:gestionnaire) }
    let(:token) { gestionnaire.user.send(:set_reset_password_token) }
    let(:password) { '{another-password-ok?}' }

    before { post :create, params: { gestionnaire: { reset_password_token: token, password: password } } }

    context 'when the token is ok' do
      it do
        expect(gestionnaire.user.reload.valid_password?(password)).to be true
        expect(response).to redirect_to(gestionnaire_groupe_gestionnaires_path)
      end
    end

    context 'when the token is bad' do
      let(:token) { 'bad' }

      it do
        expect(gestionnaire.user.reload.valid_password?(password)).to be false
        expect(response).to redirect_to(gestionnaires_activate_path(token: token))
      end
    end
  end
end
