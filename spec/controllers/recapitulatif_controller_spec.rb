require 'spec_helper'

RSpec.describe RecapitulatifController, type: :controller do
  let(:dossier) { create(:dossier) }

  let (:bad_dossier_id) { Dossier.count + 10 }

  describe "GET #show" do
    it "returns http success" do
      get :show, dossier_id: dossier.id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers start si mauvais dossier ID' do
      get :show, dossier_id: bad_dossier_id
      expect(response).to redirect_to('/start/error_dossier')
    end
  end
end
