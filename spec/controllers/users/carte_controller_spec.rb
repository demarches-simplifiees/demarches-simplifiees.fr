require 'spec_helper'

RSpec.describe Users::CarteController, type: :controller do
  let(:bad_adresse) { 'babouba' }

  let(:dossier) { create(:dossier, :with_user, :with_procedure) }
  let!(:entreprise) { create(:entreprise, dossier: dossier) }
  let!(:etablissement) { create(:etablissement, dossier: dossier) }
  let(:bad_dossier_id) { Dossier.count + 1000 }
  let(:adresse) { etablissement.adresse }

  before do
    sign_in dossier.user
  end

  describe 'GET #show' do
    context 'user is not connected' do
      before do
        sign_out dossier.user
      end

      it 'redirects to users/sign_in' do
        get :show, dossier_id: dossier.id
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    it 'returns http success' do
      get :show, dossier_id: dossier.id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers la liste des dossiers du user si dossier ID n\'existe pas' do
      get :show, dossier_id: bad_dossier_id
      expect(response).to redirect_to(root_path)
    end

    it_behaves_like "not owner of dossier", :show
  end

  describe 'POST #save' do
    context 'Aucune localisation n\'a jamais été enregistrée' do
      it do
        post :save, dossier_id: dossier.id, json_latlngs: ''
        expect(response).to redirect_to("/users/dossiers/#{dossier.id}/description")
      end
    end

    context 'En train de modifier la localisation' do
      let(:dossier) { create(:dossier, :with_procedure, :with_user, state: 'initiated') }
      before do
        post :save, dossier_id: dossier.id, json_latlngs: ''
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
          expect(subject.dossier.id).to eq(dossier.id)
        end
      end

      it 'Redirection vers la page récapitulatif' do
        expect(response).to redirect_to("/users/dossiers/#{dossier.id}/recapitulatif")
      end
    end

    describe 'Save quartier prioritaire' do
      before do
        allow_any_instance_of(CARTO::SGMAP::QuartierPrioritaireAdapter).
            to receive(:to_params).
                   and_return({"QPCODE1234" => {:code => "QPCODE1234", :nom => "QP de test", :commune => "Paris", :geometry => {:type => "MultiPolygon", :coordinates => [[[[2.38715792094576, 48.8723062632126], [2.38724851642619, 48.8721392348061]]]]}}})

        post :save, dossier_id: dossier.id, json_latlngs: json_latlngs
      end

      context 'when json_latlngs params is empty' do
        context 'when dossier have quartier prioritaire in database' do
          let!(:dossier) { create(:dossier, :with_user, :with_procedure, :with_two_quartier_prioritaires) }

          before do
            dossier.reload
          end

          context 'when value is empty' do
            let(:json_latlngs) { '' }
            it { expect(dossier.quartier_prioritaires.size).to eq(0) }
          end

          context 'when value is empty array' do
            let(:json_latlngs) { '[]' }
            it { expect(dossier.quartier_prioritaires.size).to eq(0) }
          end
        end
      end

      context 'when json_latlngs params is informed' do
        let(:json_latlngs) { '[[{"lat":48.87442541960633,"lng":2.3859214782714844},{"lat":48.87273183590832,"lng":2.3850631713867183},{"lat":48.87081237174292,"lng":2.3809432983398438},{"lat":48.8712640169951,"lng":2.377510070800781},{"lat":48.87510283703279,"lng":2.3778533935546875},{"lat":48.87544154230615,"lng":2.382831573486328},{"lat":48.87442541960633,"lng":2.3859214782714844}]]' }

        before do
          dossier.reload
        end

        it { expect(dossier.quartier_prioritaires.size).to eq(1) }

        describe 'Quartier Prioritaire' do
          subject { QuartierPrioritaire.last }

          it { expect(subject.code).to eq('QPCODE1234') }
          it { expect(subject.commune).to eq('Paris') }
          it { expect(subject.nom).to eq('QP de test') }
          it { expect(subject.dossier_id).to eq(dossier.id) }
        end
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

      subject { JSON.parse(response.body) }

      it 'on enregistre des coordonnées lat et lon à 0' do
        expect(subject['lat']).to eq('0')
        expect(subject['lon']).to eq('0')
      end
    end

    context 'retour d\'un fichier JSON avec 3 attributs' do
      before do
        stub_request(:get, "http://api-adresse.data.gouv.fr/search?limit=1&q=#{adresse}")
            .to_return(status: 200, body: '{"query": "50 avenue des champs u00e9lysu00e9es Paris 75008", "version": "draft", "licence": "ODbL 1.0", "features": [{"geometry": {"coordinates": [2.306888, 48.870374], "type": "Point"}, "type": "Feature", "properties": {"city": "Paris", "label": "50 Avenue des Champs u00c9lysu00e9es 75008 Paris", "housenumber": "50", "id": "ADRNIVX_0000000270748251", "postcode": "75008", "name": "50 Avenue des Champs u00c9lysu00e9es", "citycode": "75108", "context": "75, u00cele-de-France", "score": 0.9054545454545454, "type": "housenumber"}}], "type": "FeatureCollection", "attribution": "BAN"}', headers: {})

        get :get_position, dossier_id: dossier.id
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

  describe 'POST #get_qp' do
    before do
      allow_any_instance_of(CARTO::SGMAP::QuartierPrioritaireAdapter).
          to receive(:to_params).
                 and_return({"QPCODE1234" => {:code => "QPCODE1234", :geometry => {:type => "MultiPolygon", :coordinates => [[[[2.38715792094576, 48.8723062632126], [2.38724851642619, 48.8721392348061]]]]}}})

      post :get_qp, dossier_id: dossier.id, coordinates: coordinates
    end

    context 'when coordinates are empty' do
      let(:coordinates) { '[]' }

      subject { JSON.parse(response.body) }

      it 'Quartier Prioritaire Adapter does not call' do
        expect(subject['quartier_prioritaires']).to eq({})
      end
    end

    context 'when coordinates are informed' do
      let(:coordinates) { '[[{"lat":48.87442541960633,"lng":2.3859214782714844},{"lat":48.87273183590832,"lng":2.3850631713867183},{"lat":48.87081237174292,"lng":2.3809432983398438},{"lat":48.8712640169951,"lng":2.377510070800781},{"lat":48.87510283703279,"lng":2.3778533935546875},{"lat":48.87544154230615,"lng":2.382831573486328},{"lat":48.87442541960633,"lng":2.3859214782714844}]]' }

      subject { JSON.parse(response.body)['quartier_prioritaires'] }
      it { expect(subject).not_to be_nil }
      it { expect(subject['QPCODE1234']['code']).to eq('QPCODE1234') }
      it { expect(subject['QPCODE1234']['geometry']['type']).to eq('MultiPolygon') }
      it { expect(subject['QPCODE1234']['geometry']['coordinates']).to eq([[[[2.38715792094576, 48.8723062632126], [2.38724851642619, 48.8721392348061]]]]) }
    end
  end
end
