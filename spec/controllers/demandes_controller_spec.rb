require 'spec_helper'

RSpec.describe DemandesController, type: :controller do

  let (:dossier_id){10000}

  describe "GET #show" do
    it "returns http success" do
      get :show, :dossier_id => dossier_id
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #choice' do
    context 'dans tous les cas on affiche la carte' do
      it {
        post :choice, :dossier_id => dossier_id, :type_demande => '1'
        expect(response).to redirect_to("/dossiers/#{dossier_id}/carte")
      }
    end
  end
end
