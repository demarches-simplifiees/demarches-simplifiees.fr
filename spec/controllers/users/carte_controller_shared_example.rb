shared_examples 'carte_controller_spec' do
  describe 'GET #show' do
    describe 'before_action authorized_routes?' do
      context 'when dossier’s procedure have api carto actived' do
        context 'when dossier does not have a valid state' do
          before do
            dossier.state = 'received'
            dossier.save

            get :show, params: {dossier_id: dossier.id}
          end

          it { is_expected.to redirect_to root_path }
        end
      end

      context 'when dossier’s procedure does not have api carto actived' do
        let(:dossier) { create(:dossier) }

        before do
          get :show, params: {dossier_id: dossier.id}
        end

        it { is_expected.to redirect_to(root_path) }
      end
    end

    context 'user is not connected' do
      before do
        sign_out user
      end

      it 'redirects to users/sign_in' do
        get :show, params: {dossier_id: dossier.id}
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    it 'returns http success if carto is activated' do
      get :show, params: {dossier_id: dossier.id}
      expect(response).to have_http_status(:success)
    end

    context 'when procedure not have activate api carto' do
      it 'redirection on user dossier list' do
        get :show, params: {dossier_id: dossier_with_no_carto.id}
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when dossier id not exist' do
      it 'redirection on user dossier list' do
        get :show, params: {dossier_id: bad_dossier_id}
        expect(response).to redirect_to(root_path)
      end
    end

    it_behaves_like "not owner of dossier", :show
  end

  describe 'POST #save' do
    context 'Aucune localisation n\'a jamais été enregistrée' do
      it do
        post :save, params: {dossier_id: dossier.id, json_latlngs: ''}
        expect(response).to redirect_to("/users/dossiers/#{dossier.id}/description")
      end
    end

    context 'En train de modifier la localisation' do
      let(:dossier) { create(:dossier, state: 'en_construction') }
      before do
        post :save, params: {dossier_id: dossier.id, json_latlngs: ''}
      end

      it 'Redirection vers la page récapitulatif' do
        expect(response).to redirect_to("/users/dossiers/#{dossier.id}/recapitulatif")
      end
    end

    describe 'Save quartier prioritaire' do
      let(:module_api_carto) { create(:module_api_carto, :with_quartiers_prioritaires) }

      before do
        allow_any_instance_of(CARTO::SGMAP::QuartiersPrioritaires::Adapter)
            .to receive(:to_params)
                   .and_return({"QPCODE1234" => {:code => "QPCODE1234", :nom => "QP de test", :commune => "Paris", :geometry => {:type => "MultiPolygon", :coordinates => [[[[2.38715792094576, 48.8723062632126], [2.38724851642619, 48.8721392348061]]]]}}})

        post :save, params: {dossier_id: dossier.id, json_latlngs: json_latlngs}
      end

      context 'when json_latlngs params is empty' do
        context 'when dossier have quartier prioritaire in database' do
          let!(:dossier) { create(:dossier, :with_two_quartier_prioritaires) }

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

    describe 'Save cadastre' do
      let(:module_api_carto) { create(:module_api_carto, :with_cadastre) }

      before do
        allow_any_instance_of(CARTO::SGMAP::Cadastre::Adapter)
            .to receive(:to_params)
                   .and_return([{:surface_intersection => "0.0006", :surface_parcelle => 11252.692583090324, :numero => "0013", :feuille => 1, :section => "CD", :code_dep => "30", :nom_com => "Le Grau-du-Roi", :code_com => "133", :code_arr => "000", :geometry => {:type => "MultiPolygon", :coordinates => [[[[4.134084, 43.5209193], [4.1346615, 43.5212035], [4.1346984, 43.521189], [4.135096, 43.5213848], [4.1350839, 43.5214122], [4.1352697, 43.521505], [4.1356278, 43.5211065], [4.1357402, 43.5207188], [4.1350935, 43.5203936], [4.135002, 43.5204366], [4.1346051, 43.5202412], [4.134584, 43.5202472], [4.1345572, 43.5202551], [4.134356, 43.5203137], [4.1342488, 43.5203448], [4.134084, 43.5209193]]]]}}])

        post :save, params: {dossier_id: dossier.id, json_latlngs: json_latlngs}
      end

      context 'when json_latlngs params is empty' do
        context 'when dossier have cadastres in database' do
          let!(:dossier) { create(:dossier, :with_two_cadastres) }

          before do
            dossier.reload
          end

          context 'when value is empty' do
            let(:json_latlngs) { '' }
            it { expect(dossier.cadastres.size).to eq(0) }
          end

          context 'when value is empty array' do
            let(:json_latlngs) { '[]' }
            it { expect(dossier.cadastres.size).to eq(0) }
          end
        end
      end

      context 'when json_latlngs params is informed' do
        let(:json_latlngs) { '[[{"lat":48.87442541960633,"lng":2.3859214782714844},{"lat":48.87273183590832,"lng":2.3850631713867183},{"lat":48.87081237174292,"lng":2.3809432983398438},{"lat":48.8712640169951,"lng":2.377510070800781},{"lat":48.87510283703279,"lng":2.3778533935546875},{"lat":48.87544154230615,"lng":2.382831573486328},{"lat":48.87442541960633,"lng":2.3859214782714844}]]' }

        it { expect(dossier.cadastres.size).to eq(1) }

        describe 'Cadastre' do
          subject { Cadastre.last }

          it { expect(subject.surface_intersection).to eq('0.0006') }
          it { expect(subject.surface_parcelle).to eq(11252.6925830903) }
          it { expect(subject.numero).to eq('0013') }
          it { expect(subject.feuille).to eq(1) }
          it { expect(subject.section).to eq('CD') }
          it { expect(subject.code_dep).to eq('30') }
          it { expect(subject.nom_com).to eq('Le Grau-du-Roi') }
          it { expect(subject.code_com).to eq('133') }
          it { expect(subject.code_arr).to eq('000') }
          it { expect(subject.geometry).to eq({"type" => "MultiPolygon", "coordinates" => [[[[4.134084, 43.5209193], [4.1346615, 43.5212035], [4.1346984, 43.521189], [4.135096, 43.5213848], [4.1350839, 43.5214122], [4.1352697, 43.521505], [4.1356278, 43.5211065], [4.1357402, 43.5207188], [4.1350935, 43.5203936], [4.135002, 43.5204366], [4.1346051, 43.5202412], [4.134584, 43.5202472], [4.1345572, 43.5202551], [4.134356, 43.5203137], [4.1342488, 43.5203448], [4.134084, 43.5209193]]]]}) }
        end
      end
    end
  end

  describe '#get_position' do
    context 'when etablissement is nil' do
      before do
        dossier.update etablissement: nil

        stub_request(:get, /http:\/\/api-adresse[.]data[.]gouv[.]fr\/search[?]limit=1&q=/)
            .to_return(status: 200, body: '{"query": "babouba", "version": "draft", "licence": "ODbL 1.0", "features": [], "type": "FeatureCollection", "attribution": "BAN"}', headers: {})
        get :get_position, params: {dossier_id: dossier.id}
      end

      subject { JSON.parse(response.body) }

      it 'on enregistre des coordonnées lat et lon avec les valeurs par defaut' do
        expect(subject['lat']).to eq('46.538192')
        expect(subject['lon']).to eq('2.428462')
      end
    end

    context 'Geocodeur renvoie les positions par defaut' do
      let(:etablissement) { create(:etablissement, adresse: bad_adresse, numero_voie: 'dzj', type_voie: 'fzjfk', nom_voie: 'hdidjkz', complement_adresse: 'fjef', code_postal: 'fjeiefk', localite: 'zjfkfz') }
      let(:dossier) { create(:dossier, etablissement: etablissement) }

      before do
        stub_request(:get, /http:\/\/api-adresse[.]data[.]gouv[.]fr\/search[?]limit=1&q=/)
            .to_return(status: 200, body: '{"query": "babouba", "version": "draft", "licence": "ODbL 1.0", "features": [], "type": "FeatureCollection", "attribution": "BAN"}', headers: {})
        get :get_position, params: {dossier_id: dossier.id}
      end

      subject { JSON.parse(response.body) }

      it 'on enregistre des coordonnées lat et lon avec les valeurs par defaut' do
        expect(subject['lat']).to eq('46.538192')
        expect(subject['lon']).to eq('2.428462')
      end
    end

    context 'retour d\'un fichier JSON avec 3 attributs' do
      before do
        stub_request(:get, "http://api-adresse.data.gouv.fr/search?limit=1&q=#{adresse}")
            .to_return(status: 200, body: '{"query": "50 avenue des champs u00e9lysu00e9es Paris 75008", "version": "draft", "licence": "ODbL 1.0", "features": [{"geometry": {"coordinates": [2.306888, 48.870374], "type": "Point"}, "type": "Feature", "properties": {"city": "Paris", "label": "50 Avenue des Champs u00c9lysu00e9es 75008 Paris", "housenumber": "50", "id": "ADRNIVX_0000000270748251", "postcode": "75008", "name": "50 Avenue des Champs u00c9lysu00e9es", "citycode": "75108", "context": "75, u00cele-de-France", "score": 0.9054545454545454, "type": "housenumber"}}], "type": "FeatureCollection", "attribution": "BAN"}', headers: {})

        get :get_position, params: {dossier_id: dossier.id}
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
      allow_any_instance_of(CARTO::SGMAP::QuartiersPrioritaires::Adapter)
          .to receive(:to_params)
                 .and_return({"QPCODE1234" => {:code => "QPCODE1234", :geometry => {:type => "MultiPolygon", :coordinates => [[[[2.38715792094576, 48.8723062632126], [2.38724851642619, 48.8721392348061]]]]}}})

      post :get_qp, params: {dossier_id: dossier.id, coordinates: coordinates}
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
