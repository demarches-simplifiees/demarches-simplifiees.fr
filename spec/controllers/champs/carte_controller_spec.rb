require 'spec_helper'

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
  let(:geojson) { [] }
  let(:champ) do
    create(:type_de_champ_carte, options: {
      quartiers_prioritaires: true
    }).champ.create(dossier: dossier, value: geojson.to_json)
  end

  describe 'POST #show' do
    render_views

    context 'when the API is available' do
      render_views

      before do
        sign_in user

        allow_any_instance_of(ApiCarto::QuartiersPrioritairesAdapter)
          .to receive(:results)
          .and_return([{ code: "QPCODE1234", geometry: { type: "MultiPolygon", coordinates: [[[[2.38715792094576, 48.8723062632126], [2.38724851642619, 48.8721392348061]]]] } }])

        post :show, params: params, format: 'js'
      end

      context 'when coordinates are empty' do
        let(:value) { '[]' }

        it {
          expect(assigns(:error)).to eq(nil)
          expect(champ.reload.value).to eq(nil)
          expect(champ.reload.geo_areas).to eq([])
          expect(response.body).to include("DS.fire('carte:update', {\"selector\":\".carte-1\",\"data\":{\"position\":{\"lon\":\"2.428462\",\"lat\":\"46.538192\",\"zoom\":\"13\"},\"selection\":null,\"quartiersPrioritaires\":[],\"cadastres\":[],\"parcellesAgricoles\":[]}});")
        }
      end

      context 'when coordinates are informed' do
        let(:value) { [[{ "lat": 48.87442541960633, "lng": 2.3859214782714844 }, { "lat": 48.87273183590832, "lng": 2.3850631713867183 }, { "lat": 48.87081237174292, "lng": 2.3809432983398438 }, { "lat": 48.8712640169951, "lng": 2.377510070800781 }, { "lat": 48.87510283703279, "lng": 2.3778533935546875 }, { "lat": 48.87544154230615, "lng": 2.382831573486328 }, { "lat": 48.87442541960633, "lng": 2.3859214782714844 }]].to_json }

        it { expect(response.body).not_to be_nil }
        it { expect(response.body).to include('MultiPolygon') }
        it { expect(response.body).to include('[2.38715792094576,48.8723062632126]') }
      end

      context 'when error' do
        let(:geojson) { [[{ "lat": 48.87442541960633, "lng": 2.3859214782714844 }, { "lat": 48.87273183590832, "lng": 2.3850631713867183 }, { "lat": 48.87081237174292, "lng": 2.3809432983398438 }, { "lat": 48.8712640169951, "lng": 2.377510070800781 }, { "lat": 48.87510283703279, "lng": 2.3778533935546875 }, { "lat": 48.87544154230615, "lng": 2.382831573486328 }, { "lat": 48.87442541960633, "lng": 2.3859214782714844 }]] }
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

        allow_any_instance_of(ApiCarto::QuartiersPrioritairesAdapter)
          .to receive(:results)
          .and_raise(RestClient::ResourceNotFound)

        post :show, params: params, format: 'js'
      end

      let(:value) { [[{ "lat": 48.87442541960633, "lng": 2.3859214782714844 }, { "lat": 48.87273183590832, "lng": 2.3850631713867183 }, { "lat": 48.87081237174292, "lng": 2.3809432983398438 }, { "lat": 48.8712640169951, "lng": 2.377510070800781 }, { "lat": 48.87510283703279, "lng": 2.3778533935546875 }, { "lat": 48.87544154230615, "lng": 2.382831573486328 }, { "lat": 48.87442541960633, "lng": 2.3859214782714844 }]].to_json }

      it { expect(response.status).to eq 503 }
      it { expect(response.body).to include('Les données cartographiques sont temporairement indisponibles') }
    end
  end
end
