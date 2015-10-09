require 'spec_helper'

RSpec.describe Users::CarteController, type: :controller do
  let(:bad_adresse) { 'babouba' }

  let(:dossier) { create(:dossier, :with_user, :with_procedure) }
  let!(:entreprise) { create(:entreprise, dossier: dossier) }
  let!(:etablissement) { create(:etablissement, dossier: dossier) }
  let(:dossier_id) { dossier.id }
  let(:bad_dossier_id) { Dossier.count + 1000 }
  let(:ref_dossier_carto) { 'IATRQPQY' }
  let(:adresse) { etablissement.adresse }

  before do
    sign_in dossier.user
  end

  describe 'GET #show' do

    context 'user is not connected' do
      before do
        sign_out dossier.user
      end

      it 'redirect to users/sign_in' do
        get :show, dossier_id: dossier_id
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    it 'returns http success' do
      get :show, dossier_id: dossier_id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers la liste des dossiers du user si dossier ID n\'existe pas' do
      get :show, dossier_id: bad_dossier_id
      expect(response).to redirect_to(controller: :dossiers, action: :index)
    end
  end

  describe 'POST #save_ref_api_carto' do
    context 'Aucune localisation n\'a jamais été enregistrée' do
      it do
        post :save_ref_api_carto, dossier_id: dossier_id, ref_dossier_carto: ref_dossier_carto
        expect(response).to redirect_to("/users/dossiers/#{dossier_id}/description")
      end
    end

    context 'En train de modifier la localisation' do
      let(:dossier) { create(:dossier, :with_procedure, :with_user, ref_dossier_carto: ref_dossier_carto, state: 'proposed') }
      before do
        post :save_ref_api_carto, dossier_id: dossier_id, ref_dossier_carto: ref_dossier_carto
      end

      context 'Enregistrement d\'un commentaire informant la modification' do
        subject { dossier.commentaires.last }

        it 'champs email' do
          expect(subject.email).to eq('Modification localisation')
        end

        it 'champs body' do
          expect(subject.body).to eq('La localisation de la demande a été modifiée. Merci de le prendre en compte.')
        end

        it 'champs dossier' do
          expect(subject.dossier.id).to eq(dossier_id)
        end
      end

      it 'Redirection vers la page récapitulatif' do
        expect(response).to redirect_to("/users/dossiers/#{dossier_id}/recapitulatif")
      end
    end
  end

  describe '#get_position' do
    context 'Geocodeur renvoie des positions nil' do
      let(:etablissement) { create(:etablissement, adresse: bad_adresse) }
      let(:dossier) { create(:dossier, :with_procedure, :with_user, etablissement: etablissement) }
      before do
        stub_request(:get, "http://api-adresse.data.gouv.fr/search?limit=1&q=#{bad_adresse}")
          .to_return(status: 200, body: '{"query": "babouba", "version": "draft", "licence": "ODbL 1.0", "features": [], "type": "FeatureCollection", "attribution": "BAN"}', headers: {})
        get :get_position, dossier_id: dossier.id
      end

      subject { dossier.reload }

      it 'on enregistre des coordonnées lat et lon à 0' do
        expect(subject.position_lat).to eq('0')
        expect(subject.position_lon).to eq('0')
      end
    end

    context 'retour d\'un fichier JSON avec 3 attributs' do
      before do
        stub_request(:get, "http://api-adresse.data.gouv.fr/search?limit=1&q=#{adresse}")
          .to_return(status: 200, body: '{"query": "50 avenue des champs \u00e9lys\u00e9es Paris 75008", "version": "draft", "licence": "ODbL 1.0", "features": [{"geometry": {"coordinates": [2.306888, 48.870374], "type": "Point"}, "type": "Feature", "properties": {"city": "Paris", "label": "50 Avenue des Champs \u00c9lys\u00e9es 75008 Paris", "housenumber": "50", "id": "ADRNIVX_0000000270748251", "postcode": "75008", "name": "50 Avenue des Champs \u00c9lys\u00e9es", "citycode": "75108", "context": "75, \u00cele-de-France", "score": 0.9054545454545454, "type": "housenumber"}}], "type": "FeatureCollection", "attribution": "BAN"}', headers: {})

        get :get_position, dossier_id: dossier_id
      end
      subject { JSON.parse(response.body) }

      it 'format JSON valide' do
        expect(response.content_type).to eq('application/json')
      end

      it 'latitude' do
        expect(subject['lat']).to eq('48.870374')
      end

      it 'longitude' do
        expect(subject['lon']).to eq('2.306888')
      end

      it 'dossier_id' do
        expect(subject['dossier_id']).to eq(dossier.id.to_s)
      end
    end
  end
end
