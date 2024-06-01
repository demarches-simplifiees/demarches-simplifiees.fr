describe Administrateurs::ServicesController, type: :controller do
  let(:admin) { administrateurs(:default_admin) }
  let(:procedure) { create(:procedure, administrateur: admin) }

  describe '#create' do
    before do
      sign_in(admin.user)
      post :create, params: params
    end

    context 'when submitting a new service' do
      let(:params) do
        {
          service: {
            nom: 'super service',
            organisme: 'organisme',
            type_organisme: 'association',
            email: 'email@toto.com',
            telephone: '1234',
            horaires: 'horaires',
            adresse: 'adresse',
            siret: "35600082800018"
          },
          procedure_id: procedure.id
        }
      end

      it do
        expect(flash.alert).to be_nil
        expect(flash.notice).to eq('super service créé')
        expect(Service.last.nom).to eq('super service')
        expect(Service.last.organisme).to eq('organisme')
        expect(Service.last.type_organisme).to eq(Service.type_organismes.fetch(:association))
        expect(Service.last.email).to eq('email@toto.com')
        expect(Service.last.telephone).to eq('1234')
        expect(Service.last.horaires).to eq('horaires')
        expect(Service.last.adresse).to eq('adresse')
        expect(Service.last.siret).to eq('35600082800018')
        expect(APIEntreprise::ServiceJob).to have_been_enqueued.with(Service.last.id)

        expect(response).to redirect_to(admin_services_path(procedure_id: procedure.id))
      end
    end

    context 'when submitting an invalid service' do
      let(:params) { { service: { nom: 'super service' }, procedure_id: procedure.id } }

      it { expect(flash.alert).not_to be_nil }
      it { expect(response).to render_template(:new) }
      it { expect(assigns(:service).nom).to eq('super service') }
    end
  end

  describe '#update' do
    let!(:service) { create(:service, administrateur: admin) }
    let(:service_params) { { nom: 'nom', type_organisme: Service.type_organismes.fetch(:association), siret: "13002526500013" } }

    before do
      sign_in(admin.user)
      params = {
        id: service.id,
        service: service_params,
        procedure_id: procedure.id
      }
      patch :update, params: params
    end

    context 'when updating a service' do
      it { expect(flash.alert).to be_nil }
      it { expect(flash.notice).to eq('nom modifié') }
      it { expect(Service.last.nom).to eq('nom') }
      it { expect(Service.last.type_organisme).to eq(Service.type_organismes.fetch(:association)) }
      it { expect(response).to redirect_to(admin_services_path(procedure_id: procedure.id)) }
      it { expect(APIEntreprise::ServiceJob).to have_been_enqueued.with(service.id) }
    end

    context 'when updating a service with invalid data' do
      let(:service_params) { { nom: '', type_organisme: Service.type_organismes.fetch(:association) } }

      it { expect(flash.alert).not_to be_nil }
      it { expect(response).to render_template(:edit) }
    end
  end

  describe '#add_to_procedure' do
    let!(:procedure) { create(:procedure, administrateur: admin) }
    let!(:service) { create(:service, administrateur: admin) }

    def post_add_to_procedure
      sign_in(admin.user)
      params = {
        procedure: {
          id: procedure.id,
          service_id: service.id
        }
      }
      patch :add_to_procedure, params: params
      procedure.reload
    end

    context 'when adding a service to a procedure' do
      before { post_add_to_procedure }

      it { expect(flash.alert).to be_nil }
      it { expect(flash.notice).to eq("service affecté : #{service.nom}") }
      it { expect(procedure.service_id).to eq(service.id) }
      it { expect(response).to redirect_to(admin_procedure_path(procedure.id)) }
    end

    context 'when stealing a service to add it to a procedure' do
      let!(:service) { create(:service) }

      it { expect { post_add_to_procedure }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end

  describe '#destroy' do
    let!(:service) { create(:service, administrateur: admin) }

    context 'when a service has no related procedure' do
      before do
        sign_in(admin.user)
        delete :destroy, params: { id: service.id, procedure_id: procedure.id }
      end

      it { expect { service.reload }.to raise_error(ActiveRecord::RecordNotFound) }
      it { expect(flash.alert).to be_nil }
      it { expect(flash.notice).to eq("#{service.nom} est supprimé") }
      it { expect(response).to redirect_to(admin_services_path(procedure_id: procedure.id)) }
    end

    context 'when a service still has some related procedures' do
      let!(:procedure) { create(:procedure, service: service) }

      before do
        sign_in(admin.user)
        delete :destroy, params: { id: service.id, procedure_id: procedure.id }
      end

      it { expect(service.reload).not_to be_nil }
      it { expect(flash.alert).to eq("la démarche #{procedure.libelle} utilise encore le service #{service.nom}. Veuillez l'affecter à un autre service avant de pouvoir le supprimer") }
      it { expect(flash.notice).to be_nil }
      it { expect(response).to redirect_to(admin_services_path(procedure_id: procedure.id)) }
    end

    context "when a service has some related discarded procedures" do
      let!(:procedure) { create(:procedure, :discarded, service: service) }

      before do
        sign_in(admin.user)
        delete :destroy, params: { id: service.id, procedure_id: procedure.id }
      end

      it { expect { service.reload }.to raise_error(ActiveRecord::RecordNotFound) }
      it { expect(flash.alert).to be_nil }
      it { expect(flash.notice).to eq("#{service.nom} est supprimé") }
      it { expect(procedure.reload.service_id).to be_nil }
    end
  end

  describe "#index" do
    let(:admin) { administrateurs(:default_admin) }

    before do
      sign_in(admin.user)
    end

    context 'when admin has service without siret' do
      let(:service) { create(:service) }
      let(:procedure) { create(:procedure, :published, service: service, administrateur: admin) }

      it 'display alert when admin has service without siret' do
        service.siret = nil
        service.save(validate: false)
        get :index, params: { procedure_id: procedure.id }
        expect(flash.alert.first).to eq "Vous n’avez pas renseigné le siret du service pour certaines de vos démarches. Merci de les modifier."
        expect(flash.alert.last).to include(service.nom)
      end
    end

    context 'when admin has procedure without service' do
      let(:procedure) { create(:procedure, :published, service: nil, administrateur: admin) }

      it 'display alert' do
        get :index, params: { procedure_id: procedure.id }
        expect(procedure.service).to be nil
        expect(flash.alert.first).to eq "Certaines de vos démarches n’ont pas de service associé."
        expect(flash.alert.last).to include "démarche #{procedure.id}"
      end
    end
  end
end
