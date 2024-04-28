# frozen_string_literal: true

describe Champs::CarteController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :carte, options: { cadastres: true } }]) }
  let(:dossier) { create(:dossier, user: user, procedure: procedure) }
  let(:params) do
    {
      dossier: {
        champs_public_attributes: {
          champ.public_id => { value: value }
        }
      },
      position: '1',
      dossier_id: champ.dossier_id,
      stable_id: champ.stable_id
    }
  end
  let(:champ) { dossier.champs.first }

  describe 'features' do
    let(:feature) { attributes_for(:geo_area, :polygon) }
    let(:geo_area) { create(:geo_area, :selection_utilisateur, :polygon, champ: champ) }
    let(:params) do
      {
        dossier_id: champ.dossier_id,
        stable_id: champ.stable_id,
        feature: feature,
        source: GeoArea.sources.fetch(:selection_utilisateur)
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

      context 'success' do
        it { expect(response.status).to eq 201 }
      end

      context 'error' do
        let(:feature) { attributes_for(:geo_area, :invalid_point) }
        let(:params) do
          {
            dossier_id: champ.dossier_id,
            stable_id: champ.stable_id,
            feature: feature,
            source: GeoArea.sources.fetch(:selection_utilisateur)
          }
        end

        it { expect(response.status).to eq 422 }
      end
    end

    describe 'PATCH #update' do
      let(:params) do
        {
          dossier_id: champ.dossier_id,
          stable_id: champ.stable_id,
          id: geo_area.id,
          feature: feature
        }
      end

      before do
        patch :update, params: params
      end

      context 'update geometry' do
        it { expect(response.status).to eq 204 }
      end

      context 'update description' do
        let(:feature) do
          {
            properties: {
              description: 'un point'
            }
          }
        end

        it {
          expect(response.status).to eq 204
          expect(geo_area.reload.description).to eq('un point')
        }
      end

      context 'error' do
        let(:feature) { attributes_for(:geo_area, :invalid_point) }

        it { expect(response.status).to eq 422 }
      end
    end

    describe 'DELETE #destroy' do
      let(:params) do
        {
          dossier_id: champ.dossier_id,
          stable_id: champ.stable_id,
          id: geo_area.id
        }
      end

      before do
        delete :destroy, params: params
      end

      it { expect(response.status).to eq 204 }
    end

    describe 'GET #index' do
      render_views

      before do
        get :index, params: params, format: :turbo_stream
      end

      context 'without focus' do
        let(:params) do
          {
            dossier_id: champ.dossier_id,
            stable_id: champ.stable_id
          }
        end

        it 'updates the list' do
          expect(response.body).not_to include("map:feature:focus")
          expect(response.status).to eq 200
        end
      end

      context "update list and focus" do
        let(:params) do
          {
            dossier_id: champ.dossier_id,
            stable_id: champ.stable_id,
            focus: true
          }
        end

        it 'updates the list and focuses the map' do
          expect(response.body).to include(ActionView::RecordIdentifier.dom_id(champ, :geo_areas))
          expect(response.body).to include("map:feature:focus")
          expect(response.status).to eq 200
        end
      end
    end
  end
end
