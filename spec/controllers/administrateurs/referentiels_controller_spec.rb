# frozen_string_literal: true

describe Administrateurs::ReferentielsController, type: :controller do
  before { sign_in(procedure.administrateurs.first.user) }

  describe '#new' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :referentiel, stable_id: 123 }]) }
    it 'works' do
      get :new, params: { procedure_id: procedure.id, stable_id: 123 }
      expect(response).to have_http_status(:success)
    end
  end

  describe '#create' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :referentiel, stable_id: 123 }]) }
    subject { post :create, params: { procedure_id: procedure.id, stable_id: 123, referentiel: referentiel_params }, format: :turbo_stream }
    context 'partial update' do
      let(:referentiel_params) { { type: 'Referentiels::APIReferentiel' } }
      it 'update and re-render form' do
        subject
        tdc = procedure.draft_revision.types_de_champ.first

        expect(response).to have_http_status(:success)
      end
    end

    context 'full update' do
      let(:referentiel_params) do
        {
          type: 'Referentiels::APIReferentiel',
          mode: 'exact_match',
          url: 'https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/',
          hint: 'Identifiant unique du bâtiment dans le RNB, composé de 12 chiffre et lettre',
          test_data: 'PG46YY6YWCX8'
        }
      end
      it 'update and redirect' do
        subject
        referentiel = Referentiel.first
        # expect(response).to redirect_to(mapping_datasource_admin_procedure_type_de_champ_path(procedure, tdc.stable_id))

        expect(referentiel.type).to eq(referentiel_params[:type])
        expect(referentiel.mode).to eq(referentiel_params[:mode])
        expect(referentiel.url).to eq(referentiel_params[:url])
        expect(referentiel.hint).to eq(referentiel_params[:hint])
        expect(referentiel.test_data).to eq(referentiel_params[:test_data])
      end
    end
  end
end
