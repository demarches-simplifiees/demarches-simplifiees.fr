require 'spec_helper'

describe Users::RecapitulatifController, type: :controller do
  let(:dossier) { create(:dossier, :with_user) }

  let(:bad_dossier_id) { Dossier.count + 100000 }

  describe 'GET #show' do
    before do
      sign_in dossier.user
    end
    it 'returns http success' do
      get :show, dossier_id: dossier.id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers siret si mauvais dossier ID' do
      get :show, dossier_id: bad_dossier_id
      expect(response).to redirect_to('/users/siret')
    end
  end
end
