require 'spec_helper'

RSpec.describe RecapitulatifController, type: :controller do
  let (:dossier_id){10000}
  let (:bad_dossier_id){1000}

  describe "GET #show" do
    it "returns http success" do
      get :show, :dossier_id => dossier_id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers start si mauvais dossier ID' do
      get :show, :dossier_id => bad_dossier_id
      expect(response).to redirect_to('/start/error_dossier')
    end
  end
end
