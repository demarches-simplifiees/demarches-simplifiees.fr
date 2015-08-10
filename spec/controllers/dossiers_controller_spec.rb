require 'spec_helper'

RSpec.describe DossiersController, type: :controller do
  let (:dossier_id){10000}
  let (:bad_dossier_id){1000}
  let (:autorisation_donnees){'on'}

  let (:siren){431449040}
  let (:siret){43144904000028}
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
          to_return(:status => 404, :body => 'fake body', :headers => {})

      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/etablissements/#{siret}?token=#{SIADETOKEN}").
          to_return(:status => 200, :body => File.read('spec/support/files/etablissement.json'), :headers => {})

      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/entreprises/#{siren}?token=#{SIADETOKEN}").
          to_return(:status => 200, :body => File.read('spec/support/files/entreprise.json'), :headers => {})
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
    it 'Checkbox conditions validée' do
      put :update, :id => dossier_id, :autorisation_donnees => autorisation_donnees
      expect(response).to redirect_to("/dossiers/#{dossier_id}/demande")
    end

    context 'Checkbox conditions non validée' do
      before do
        put :update, :id => dossier_id
      end

      it 'affichage alert' do
        expect(flash[:alert]).to be_present
      end

      it 'Affichage message d\'erreur condition non validé' do
        expect(flash[:alert]).to have_content('Les conditions sont obligatoires.')
      end
    end
  end
end
