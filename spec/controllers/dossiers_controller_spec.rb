require 'spec_helper'

RSpec.describe DossiersController, type: :controller do
  let(:dossier) { create(:dossier, :with_entreprise) }
  let (:dossier_id) { dossier.id }
  let (:bad_dossier_id) { 999999999999 }

  let (:siren) { dossier.siren }
  let (:siret) { dossier.siret }
  let (:bad_siret){1}

  describe 'GET #show' do
    it "returns http success with dossier_id valid" do
      get :show, :id => dossier_id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers start si mauvais dossier ID' do
      get :show, :id => bad_dossier_id
      expect(response).to redirect_to('/start/error_dossier')
    end
  end

  describe 'POST #create' do
    before do
      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/etablissements/#{bad_siret}?token=#{SIADETOKEN}").
          to_return(:status => 404, :body => 'fake body')

      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/etablissements/#{siret}?token=#{SIADETOKEN}").
          to_return(:status => 200, :body => File.read('spec/support/files/etablissement.json'))

      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/entreprises/#{siren}?token=#{SIADETOKEN}").
          to_return(:status => 200, :body => File.read('spec/support/files/entreprise.json'))
    end

    context 'Le SIRET est correct' do
      it {
        post :create, :siret => siret, :pro_dossier_id => ''
        @last_dossier = ActiveRecord::Base.connection.execute("SELECT currval('dossiers_id_seq')")
        expect(response).to redirect_to("/dossiers/#{@last_dossier.getvalue(0,0)}")
      }
    end

    context 'Le SIRET n\'est pas correct' do
      it {
        post :create, :siret => bad_siret
        expect(response).to redirect_to('/start/error_siret')
      }
    end

    context 'Un numéro de dossier est envoyé avec le SIRET' do
      it 'La combinaison SIRET / dossier_id est valide' do
        post :create, :siret => siret, :pro_dossier_id => dossier_id
        expect(response).to redirect_to("/dossiers/#{dossier_id}/recapitulatif")
      end

      it 'La combinaison SIRET (ok) et dossier_id (nok) n\'est pas valide' do
        post :create, :siret => siret, :pro_dossier_id => bad_dossier_id
        expect(response).to redirect_to("/start/error_dossier")
      end
    end
  end

  describe 'PUT #update' do
    context 'when Checkbox is checked' do
      it 'redirects to demande' do
        put :update, :id => dossier_id, dossier: { autorisation_donnees: '1' }
        expect(response).to redirect_to("/dossiers/#{dossier_id}/demande")
      end

      it 'update dossier' do
        put :update, :id => dossier_id, dossier: { autorisation_donnees: '1' }
        dossier = Dossier.find(dossier_id)
        expect(dossier.autorisation_donnees).to be_truthy
      end
    end

    context 'when Checkbox is not checked' do
      it 'uses flash alert to display message' do
        put :update, :id => dossier_id, dossier: { autorisation_donnees: '0' }
        expect(flash[:alert]).to have_content('Les conditions sont obligatoires.')
      end

      it "doesn't update dossier autorisation_donnees" do
        put :update, :id => dossier_id, dossier: { autorisation_donnees: '0' }
        dossier = Dossier.find(dossier_id)
        expect(dossier.autorisation_donnees).to be_falsy
      end
    end
  end
end
