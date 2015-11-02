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
      expect(response).to redirect_to('/')
    end

    it_behaves_like "not owner of dossier", :show

  end

  describe 'POST #submit' do
    context 'when an user submit his dossier' do
      before do
        post :submit, dossier_id: dossier.id
      end

      it 'dossier change his state for closed' do
        dossier.reload
        expect(dossier.state).to eq('submitted')
      end

      it 'a message informe user what his dossier is submitted' do
        expect(flash[:notice]).to include('Dossier soumis avec succès.')
      end
    end
  end

  describe 'POST #submit_validate' do
    context 'when an user depose his dossier' do
      before do
        dossier.validated!
        post :submit_validate, dossier_id: dossier.id
      end

      it 'dossier change his state for submit_validated' do
        dossier.reload
        expect(dossier.state).to eq('submit_validated')
      end

      it 'a message informe user what his dossier is submitted' do
        expect(flash[:notice]).to include('Dossier déposé avec succès.')
      end
    end
  end

end
