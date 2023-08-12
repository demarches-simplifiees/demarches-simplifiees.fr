describe Instructeurs::ContactInformationsController, type: :controller do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }
  let(:assign_to) { create(:assign_to, instructeur: instructeur, groupe_instructeur: build(:groupe_instructeur, procedure: procedure)) }
  let(:gi) { assign_to.groupe_instructeur }

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
          groupe_id: gi.id
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
end
