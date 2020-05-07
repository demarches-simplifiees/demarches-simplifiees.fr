describe Champs::CarteController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published) }
  let(:dossier) { create(:dossier, user: user, procedure: procedure) }
  let(:params) do
    {
      dossier: {
        champs_attributes: {
          '1' => { value: value }
        }
      },
      position: '1',
      champ_id: champ.id
    }
  end
  let(:champ) do
    create(:type_de_champ_carte, options: {
      cadastres: true
    }).champ.create(dossier: dossier)
  end
  describe 'features' do
    let(:feature) { attributes_for(:geo_area, :polygon) }
    let(:geo_area) { create(:geo_area, :selection_utilisateur, :polygon, champ: champ) }
    let(:params) do
      {
        champ_id: champ.id,
        feature: feature
      }
    end

    before do
      sign_in user
      request.accept = "application/json"
      request.content_type = "application/json"
    end

    describe 'POST #create' do
      before do
        post :create, params: params
      end

      it { expect(response.status).to eq 201 }
    end

    describe 'PATCH #update' do
      let(:params) do
        {
          champ_id: champ.id,
          id: geo_area.id,
          feature: feature
        }
      end

      before do
        patch :update, params: params
      end

      it { expect(response.status).to eq 204 }
    end

    describe 'DELETE #destroy' do
      let(:params) do
        {
          champ_id: champ.id,
          id: geo_area.id
        }
      end

      before do
        delete :destroy, params: params
      end

      it { expect(response.status).to eq 204 }
    end

    describe 'POST #import' do
      render_views

      let(:params) do
        {
          champ_id: champ.id,
          feature_collection: {
            features: [feature]
          }
        }
      end

      before do
        post :import, params: params
      end

      it {
        expect(response.status).to eq 201
        expect(response.body).to include("bbox")
      }
    end

    describe 'GET #index' do
      render_views

      before do
        request.accept = "application/javascript"
        request.content_type = "application/javascript"
      end

      context 'with cadastres update' do
        let(:params) do
          {
            champ_id: champ.id,
            cadastres: 'update'
          }
        end

        before do
          get :index, params: params
        end

        it {
          expect(response.status).to eq 200
          expect(response.body).to include("DS.fire('cadastres:update'")
        }
      end

      context 'without cadastres update' do
        let(:params) do
          {
            champ_id: champ.id
          }
        end

        before do
          get :index, params: params
        end

        it {
          expect(response.status).to eq 200
          expect(response.body).not_to include("DS.fire('cadastres:update'")
        }
      end
    end
  end

  describe 'POST #show' do
    render_views

    context 'when the API is available' do
      render_views

      before do
        sign_in user

        allow_any_instance_of(ApiCarto::CadastreAdapter)
          .to receive(:results)
          .and_return([{ code: "QPCODE1234", surface_parcelle: 4, geometry: { type: "MultiPolygon", coordinates: [[[[2.38715792094576, 48.8723062632126], [2.38724851642619, 48.8721392348061], [2.38724851642620, 48.8721392348064], [2.38715792094576, 48.8723062632126]]]] } }])

        post :show, params: params, format: 'js'
      end

      context 'when coordinates are empty' do
        let(:value) do
          {
            type: 'FeatureCollection',
            features: []
          }.to_json
        end

        it {
          expect(assigns(:error)).to eq(nil)
          expect(champ.reload.value).to eq(nil)
          expect(champ.reload.geo_areas).to eq([])
          expect(response.body).to include("DS.fire('carte:update'")
        }
      end

      context 'when coordinates are informed' do
        let(:value) do
          {
            type: 'FeatureCollection',
            features: [
              {
                type: 'Feature',
                properties: {
                  source: 'selection_utilisateur'
                },
                geometry: { type: 'Polygon', coordinates: [[[2.3859214782714844, 48.87442541960633], [2.3850631713867183, 48.87273183590832], [2.3809432983398438, 48.87081237174292], [2.377510070800781, 48.8712640169951], [2.3859214782714844, 48.87442541960633]]] }
              }
            ]
          }.to_json
        end

        it {
          expect(response.body).not_to be_nil
          expect(response.body).to include('MultiPolygon')
          expect(response.body).to include('[2.38715792094576,48.8723062632126]')
        }
      end

      context 'when error' do
        let(:value) { '' }

        it {
          expect(assigns(:error)).to eq(true)
          expect(champ.reload.value).to eq(nil)
          expect(champ.reload.geo_areas).to eq([])
        }
      end
    end

    context 'when the API is unavailable' do
      before do
        sign_in user

        allow_any_instance_of(ApiCarto::CadastreAdapter)
          .to receive(:results)
          .and_raise(ApiCarto::API::ResourceNotFound)

        post :show, params: params, format: 'js'
      end

      let(:value) do
        {
          type: 'FeatureCollection',
          features: [
            {
              type: 'Feature',
              properties: {
                source: 'selection_utilisateur'
              },
              geometry: { type: 'Polygon', coordinates: [[[2.3859214782714844, 48.87442541960633], [2.3850631713867183, 48.87273183590832], [2.3809432983398438, 48.87081237174292], [2.377510070800781, 48.8712640169951], [2.3859214782714844, 48.87442541960633]]] }
            }
          ]
        }.to_json
      end

      it {
        expect(response.status).to eq 503
        expect(response.body).to include('Les données cartographiques sont temporairement indisponibles')
      }
    end
  end
end
