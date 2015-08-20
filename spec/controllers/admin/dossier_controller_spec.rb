require 'rails_helper'

RSpec.describe Admin::DossierController, type: :controller do
  let(:dossier) { create(:dossier, :with_entreprise) }
  let(:dossier_id) { dossier.id }
  let(:bad_dossier_id) { Dossier.count + 10 }

  describe "GET #show" do
    context 'l\'utilisateur est connecté' do
      before do
        sign_in
      end

      it "returns http success" do
        get :show, :dossier_id => dossier_id
        expect(response).to have_http_status(200)
      end

      it 'le numéro de dossier n\'existe pas' do
        get :show, :dossier_id => bad_dossier_id
        expect(response).to redirect_to('/start/error_dossier')
      end
    end

    context 'L\'utilisateur n\'est pas connecté avec un dossier_id correct' do
      it {
        get :show, :dossier_id => dossier_id
        expect(response).to redirect_to('/')
      }
    end
  end

  describe "GET #index" do
    let(:user) { create(:user) }
    before do
      sign_in
    end

    it 'le numéro de dossier est correct' do
      get :index, :dossier_id => dossier_id
      expect(response).to redirect_to("/admin/dossiers/#{dossier_id}")
    end

    it 'il n\' y a pas de numéro de dossier' do
      get :index
      expect(response).to redirect_to('/start/error_dossier')
    end

    it 'le numéro de dossier n\'existe pas' do
      get :index, :dossier_id => bad_dossier_id
      expect(response).to redirect_to('/start/error_dossier')
    end
  end
end
