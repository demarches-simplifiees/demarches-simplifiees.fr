require 'spec_helper'

describe Users::RecapitulatifController, type: :controller do
  let(:dossier) { create(:dossier, state: 'en_construction') }
  let(:bad_dossier_id) { Dossier.count + 100000 }

  before do
    sign_in dossier.user
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, params: {dossier_id: dossier.id}
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers siret si mauvais dossier ID' do
      get :show, params: {dossier_id: bad_dossier_id}
      expect(response).to redirect_to('/')
    end

    it_behaves_like "not owner of dossier", :show

    describe 'before_action authorized_routes?' do
      context 'when dossier have brouillon state' do
        before do
          dossier.state = 'brouillon'
          dossier.save

          get :show, params: {dossier_id: dossier.id}
        end

        it { is_expected.to redirect_to root_path }
      end
    end
  end

  describe 'POST #initiate' do
    context 'when an user initiate his dossier' do
      before do
        post :initiate, params: {dossier_id: dossier.id}
      end

      it 'dossier change his state for accepte' do
        dossier.reload
        expect(dossier.state).to eq('en_construction')
      end

      it 'a message informe user what his dossier is en_construction' do
        expect(flash[:notice]).to include('Dossier soumis avec succès.')
      end
    end
  end
end
