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
      before do
        patch :update, params: params
      end

      context 'update geometry' do
        let(:params) do
          {
            champ_id: champ.id,
            id: geo_area.id,
            feature: feature
          }
        end

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
        let(:params) do
          {
            champ_id: champ.id,
            id: geo_area.id,
            feature: feature
          }
        end

        it {
          expect(response.status).to eq 204
          expect(geo_area.reload.description).to eq('un point')
        }
      end
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
          features: [feature]

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
end
