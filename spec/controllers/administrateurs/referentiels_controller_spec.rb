# frozen_string_literal: true

describe Administrateurs::ReferentielsController, type: :controller do
  before { sign_in(procedure.administrateurs.first.user) }
  let(:stable_id) { 123 }
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :referentiel, stable_id: }]) }

  describe '#new' do
    it 'works' do
      get :new, params: { procedure_id: procedure.id, stable_id: }
      expect(response).to have_http_status(:success)
    end
  end

  describe '#create' do
    subject { post :create, params: { procedure_id: procedure.id, stable_id:, referentiel: referentiel_params }, format: :turbo_stream }

    context 'partial update' do
      let(:referentiel_params) { { type: 'Referentiels::APIReferentiel' } }
      it 're-render form' do
        expect { subject }.not_to change { Referentiel.count }
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

      it 'creates referentiel and redirects to mapping' do
        expect { subject }.to change { Referentiel.count }.by(1)

        referentiel = Referentiel.first

        expect(response).to redirect_to(mapping_type_de_champ_admin_procedure_referentiel_path(procedure, stable_id, referentiel))

        expect(referentiel.types_de_champ).to include(TypeDeChamp.find_by(stable_id:))
        expect(referentiel.type).to eq(referentiel_params[:type])
        expect(referentiel.mode).to eq(referentiel_params[:mode])
        expect(referentiel.url).to eq(referentiel_params[:url])
        expect(referentiel.hint).to eq(referentiel_params[:hint])
        expect(referentiel.test_data).to eq(referentiel_params[:test_data])
      end
    end
  end

  describe "#edit" do
    let(:type_de_champ) { procedure.draft_revision.types_de_champ.first }
    let(:referentiel) { create(:api_referentiel, :configured, types_de_champ: [type_de_champ]) }

    it 'works' do
      get :edit, params: { procedure_id: procedure.id, stable_id:, id: referentiel.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "#update" do
    let(:type_de_champ) { procedure.draft_revision.types_de_champ.first }
    let(:referentiel) { create(:api_referentiel, :configured, types_de_champ: [type_de_champ]) }
    let(:referentiel_params) do
      {
        mode: 'autocomplete',
        url: 'https://ban.fr/{search}/',
        hint: 'Rechercher par adresse',
        test_data: '18 rue du solférino, paris'
      }
    end
    it 'works' do
      patch :update, params: { procedure_id: procedure.id, stable_id:, id: referentiel.id, referentiel: referentiel_params }
      expect(response).to have_http_status(:found)
      referentiel.reload

      expect(referentiel.mode).to eq(referentiel_params[:mode])
      expect(referentiel.url).to eq(referentiel_params[:url])
      expect(referentiel.hint).to eq(referentiel_params[:hint])
      expect(referentiel.test_data).to eq(referentiel_params[:test_data])
    end
  end
end
