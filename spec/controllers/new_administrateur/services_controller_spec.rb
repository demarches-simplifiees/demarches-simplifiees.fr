describe NewAdministrateur::ServicesController, type: :controller do
  let(:admin) { create(:administrateur) }

  describe '#create' do
    before do
      sign_in admin
      post :create, params: params
    end

    context 'when submitting a new service' do
      let(:params) { { service: { nom: 'super service', type_organisme: 'region' } } }

      it { expect(flash.alert).to be_nil }
      it { expect(flash.notice).to eq('super service créé') }
      it { expect(Service.last.nom).to eq('super service') }
      it { expect(Service.last.type_organisme).to eq('region') }
      it { expect(response).to redirect_to(services_path) }
    end

    context 'when submitting an invalid service' do
      let(:params) { { service: { nom: 'super service' } } }

      it { expect(flash.alert).not_to be_nil }
      it { expect(response).to render_template(:new) }
    end
  end
end
