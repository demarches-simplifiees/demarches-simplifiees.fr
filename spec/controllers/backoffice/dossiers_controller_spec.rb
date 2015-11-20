require 'rails_helper'

describe Backoffice::DossiersController, type: :controller do
  let(:dossier) { create(:dossier, :with_entreprise, :with_user) }
  let(:dossier_id) { dossier.id }
  let(:bad_dossier_id) { Dossier.count + 10 }
  let(:gestionnaire) { create(:gestionnaire, administrateur: create(:administrateur)) }

  describe 'GET #show' do
    context 'gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :show, id: dossier_id
        expect(response).to have_http_status(200)
      end

      it 'dossier id doesnt exist' do
        get :show, id: bad_dossier_id
        expect(response).to redirect_to('/backoffice')
      end
    end

    context 'gestionnaire doesnt connected but dossier id is correct' do
      subject { get :show, id: dossier_id }
      it { is_expected.to redirect_to('/gestionnaires/sign_in') }
    end
  end

  describe 'GET #a_traiter' do
    context 'when gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :a_traiter
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #en_attente' do
    context 'when gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :en_attente
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #termine' do
    context 'when gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :termine
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST #search' do
    before do
      sign_in gestionnaire
    end

    it 'returns http success' do
      post :search, search_terms: 'test'
      expect(response).to have_http_status(200)
    end

  end

  describe 'POST #valid' do
    before do
      dossier.initiated!
      sign_in gestionnaire
    end

    it 'dossier change is state for validated' do
      post :valid, dossier_id: dossier_id

      dossier.reload
      expect(dossier.state).to eq('validated')
    end
  end

  describe 'POST #close' do
    before do
      dossier.submitted!
      sign_in gestionnaire
    end

    it 'dossier change is state to closed' do
      post :close, dossier_id: dossier_id

      dossier.reload
      expect(dossier.state).to eq('closed')
    end
  end
end
