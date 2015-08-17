require 'spec_helper'

RSpec.describe DemandesController, type: :controller do
  let(:dossier) { create(:dossier) }
  let (:dossier_id) { dossier.id }

  describe "GET #show" do
    it "returns http success" do
      get :show, :dossier_id => dossier_id
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #choice' do
    context 'dans tous les cas on affiche la carte' do
      it {
        post :update, :dossier_id => dossier_id, :type_demande => '1'
        expect(response).to redirect_to(controller: :carte, action: :show, dossier_id: dossier_id)
      }
    end
  end
end
