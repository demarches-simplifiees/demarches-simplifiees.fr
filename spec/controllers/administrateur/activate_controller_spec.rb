describe Administrateurs::ActivateController, type: :controller do
  describe '#new' do
    let(:admin) { create(:administrateur) }
    let(:token) { admin.send(:set_reset_password_token) }

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
end
