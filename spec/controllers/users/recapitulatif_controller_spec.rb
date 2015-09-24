require 'spec_helper'

describe Users::RecapitulatifController, type: :controller do
  let(:dossier) { create(:dossier, :with_user) }
  let(:bad_dossier_id) { Dossier.count + 100000 }

  before do
    sign_in dossier.user
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, dossier_id: dossier.id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers siret si mauvais dossier ID' do
      get :show, dossier_id: bad_dossier_id
      expect(response).to redirect_to('/users/siret')
    end
  end

  describe 'POST #propose' do
    context 'when an user propose his dossier' do
      before do
        post :propose, dossier_id: dossier.id
      end

      it 'dossier change his state for processed' do
        dossier.reload
        expect(dossier.state).to eq('proposed')
      end

      it 'a message informe user what his dossier is proposed' do
        expect(flash[:notice]).to include('Dossier soumis avec succès.')
      end
    end
  end

  describe 'POST #depose' do
    context 'when an user depose his dossier' do
      before do
        dossier.confirmed!
        post :depose, dossier_id: dossier.id
      end

      it 'dossier change his state for deposed' do
        dossier.reload
        expect(dossier.state).to eq('deposited')
      end

      it 'a message informe user what his dossier is proposed' do
        expect(flash[:notice]).to include('Dossier déposé avec succès.')
      end
    end
  end

end
