# frozen_string_literal: true

describe Instructeurs::ContactInformationsController, type: :controller do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }
  let(:assign_to) { create(:assign_to, instructeur: instructeur, groupe_instructeur: build(:groupe_instructeur, procedure: procedure)) }
  let(:gi) { assign_to.groupe_instructeur }
  let(:from_admin) { nil }

  before do
    sign_in(instructeur.user)
  end

  describe '#create' do
    context 'when submitting a new contact_information' do
      let(:params) do
        {
          contact_information: {
            nom: 'super service',
            email: 'email@toto.com',
            telephone: '1234',
            horaires: 'horaires',
            adresse: 'adresse'
          },
          procedure_id: procedure.id,
          groupe_id: gi.id,
          from_admin: from_admin
        }
      end

      it do
        post :create, params: params
        expect(flash.alert).to be_nil
        expect(flash.notice).to eq('Les informations de contact ont bien été ajoutées')
        expect(ContactInformation.last.nom).to eq('super service')
        expect(ContactInformation.last.email).to eq('email@toto.com')
        expect(ContactInformation.last.telephone).to eq('1234')
        expect(ContactInformation.last.horaires).to eq('horaires')
        expect(ContactInformation.last.adresse).to eq('adresse')
      end

      context 'from admin' do
        let(:from_admin) { true }
        it do
          post :create, params: params
          expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(gi, procedure_id: procedure.id))
        end
      end
    end

    context 'when submitting an invalid contact_information' do
      before do
        post :create, params: params
      end

      let(:params) {
        {
          contact_information: {
            nom: 'super service'
          },
          procedure_id: procedure.id,
          groupe_id: gi.id
        }
      }

      it { expect(flash.alert).not_to be_nil }
      it { expect(response).to render_template(:new) }
      it { expect(assigns(:contact_information).nom).to eq('super service') }
    end
  end

  describe '#update' do
    let(:contact_information) { create(:contact_information, groupe_instructeur: gi) }
    let(:contact_information_params) {
      {
        nom: 'nom'
      }
    }
    let(:params) {
      {
        id: contact_information.id,
        contact_information: contact_information_params,
        procedure_id: procedure.id,
        groupe_id: gi.id,
        from_admin: from_admin
      }
    }

    before do
      patch :update, params: params
    end

    context 'when updating a contact_information' do
      it { expect(flash.alert).to be_nil }
      it { expect(flash.notice).to eq('Les informations de contact ont bien été modifiées') }
      it { expect(ContactInformation.last.nom).to eq('nom') }
      it { expect(response).to redirect_to(instructeur_groupe_path(gi, procedure_id: procedure.id)) }
    end

    context 'when updating a contact_information as an admin' do
      let(:from_admin) { true }
      it { expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(gi, procedure_id: procedure.id)) }
    end

    context 'when updating a contact_information with invalid data' do
      let(:contact_information_params) { { nom: '' } }

      it { expect(flash.alert).not_to be_nil }
      it { expect(response).to render_template(:edit) }
    end
  end

  describe '#destroy' do
    let(:contact_information) { create(:contact_information, groupe_instructeur: gi) }

    before do
      delete :destroy, params: { id: contact_information.id, procedure_id: procedure.id, groupe_id: gi.id }
    end

    it { expect { contact_information.reload }.to raise_error(ActiveRecord::RecordNotFound) }
    it { expect(flash.alert).to be_nil }
    it { expect(flash.notice).to eq("Les informations de contact ont bien été supprimées") }
    it { expect(response).to redirect_to(instructeur_groupe_path(gi, procedure_id: procedure.id)) }
  end
end
