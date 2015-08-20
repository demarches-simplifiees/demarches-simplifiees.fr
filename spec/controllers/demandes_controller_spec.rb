require 'spec_helper'

RSpec.describe DemandesController, type: :controller do
  let(:dossier) { create(:dossier, formulaire_id: '') }
  let(:dossier_id) { dossier.id }

  describe "GET #show" do
    it "returns http success" do
      get :show, :dossier_id => dossier_id
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #upated' do
    context 'when dossier is not linked to formulaire' do
      it 'redirect to carte controller' do
        post :update, :dossier_id => dossier_id, :formulaire => '1'
        expect(response).to redirect_to(controller: :carte, action: :show, dossier_id: dossier_id)
      end
    end
    context 'when dossier is already linked to formaulaire' do
      let(:dossier) { create(:dossier) }
      subject { post :update, :dossier_id => dossier_id, :formulaire => '1' }
      it 'raise error' do
        expect{subject}.to raise_error("La modification du formulaire n'est pas possible")
      end
    end
  end
end
