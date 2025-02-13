# frozen_string_literal: true

describe Champs::SiretController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :siret }]) }

  describe '#show' do
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }
    let(:champ) { dossier.project_champs_public.first }

    let(:champs_public_attributes) do
      champ_attributes = {}
      champ_attributes[champ.public_id] = { value: siret }
      champ_attributes
    end
    let(:params) do
      {
        dossier_id: champ.dossier_id,
        stable_id: champ.stable_id,
        dossier: {
          champs_public_attributes: champs_public_attributes
        }
      }
    end
    let(:siret) { '' }

    context 'when the user is signed in' do
      render_views
      let(:api_etablissement_status) { 200 }
      let(:api_etablissement_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }
      let(:token_expired) { false }

      before do
        sign_in user
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/etablissements\/#{siret}/)
          .to_return(status: api_etablissement_status, body: api_etablissement_body)
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siret[0..8]}/)
          .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/entreprises.json'))
        allow_any_instance_of(APIEntrepriseToken).to receive(:roles)
          .and_return(["attestations_fiscales", "attestations_sociales", "bilans_entreprise_bdf"])
        allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(token_expired)
      end

      context 'when the SIRET is empty' do
        subject { get :show, params: params, format: :turbo_stream }

        it 'clears the etablissement on the model' do
          subject
          expect(champ.reload.etablissement).to be_nil
        end

        it 'clears any information or error message' do
          subject
          expect(response.body).to include(ActionView::RecordIdentifier.dom_id(champ, :siret_info))
        end

        it 'updates dossier.last_champ_updated_at' do
          expect { subject }.to change { dossier.reload.last_champ_updated_at }
        end
      end

      context "when the SIRET is invalid because of it's length" do
        let(:siret) { '1234' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the etablissement on the model' do
          expect(champ.reload.etablissement).to be_nil
        end
      end

      context "when the SIRET is invalid because of it's checksum" do
        let(:siret) { '82812345600023' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the etablissement on the model' do
          expect(champ.reload.etablissement).to be_nil
        end
      end

      context 'when the API is unavailable due to network error' do
        let(:siret) { '82161143100015' }
        let(:api_etablissement_status) { 503 }

        before do
          expect(APIEntrepriseService).to receive(:api_insee_up?).and_return(true)
        end

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the etablissement on the model' do
          expect(champ.reload.etablissement).to be_nil
        end
      end

      context 'when the API is unavailable due to an api maintenance or pb' do
        let(:siret) { '82161143100015' }
        let(:api_etablissement_status) { 502 }

        before do
          expect(APIEntrepriseService).to receive(:api_insee_up?).and_return(false)
        end

        subject! { get :show, params: params, format: :turbo_stream }

        it 'saves the etablissement in degraded mode' do
          champ.reload
          expect(champ.etablissement.siret).to eq(siret)
          expect(champ.etablissement.as_degraded_mode?).to be true
        end
      end

      context 'when the SIRET is valid but unknown' do
        let(:siret) { '00000000000000' }
        let(:api_etablissement_status) { 404 }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the etablissement on the model' do
          expect(champ.reload.etablissement).to be_nil
        end
      end

      context 'when the SIRET informations are retrieved successfully' do
        let(:siret) { '30613890001294' }
        let(:api_etablissement_status) { 200 }
        let(:api_etablissement_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'populates the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.etablissement.siret).to eq(siret)
          expect(champ.etablissement.naf).to eq("8411Z")
          expect(dossier.reload.etablissement).to eq(nil)
        end
      end
    end

    context 'when user is not signed in' do
      subject! { get :show, params: { dossier_id: champ.dossier_id, stable_id: champ.stable_id }, format: :turbo_stream }

      it { expect(response).to redirect_to(new_user_session_path) }
    end
  end
end
