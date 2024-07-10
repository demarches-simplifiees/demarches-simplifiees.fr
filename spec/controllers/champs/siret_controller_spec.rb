describe Champs::SiretController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :siret }]) }

  describe '#show' do
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }
    let(:champ) { dossier.champs_public.first }

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
        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the etablissement on the model' do
          expect(champ.reload.etablissement).to be_nil
        end

        it 'clears any information or error message' do
          expect(response.body).to include(ActionView::RecordIdentifier.dom_id(champ, :siret_info))
        end
      end

      context "when the SIRET is invalid because of it's length" do
        let(:siret) { '1234' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the etablissement on the model' do
          expect(champ.reload.etablissement).to be_nil
        end

        it 'displays a “SIRET is invalid” error message' do
          expect(response.body).to include("Le numéro TAHITI doit comporter exactement #{SIRET_LENGTH} caractères.")
        end
      end

      context "when the SIRET is invalid because of it's checksum" do
        let(:siret) { '82812345600023' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the etablissement on the model' do
          expect(champ.reload.etablissement).to be_nil
        end

        it 'displays a “SIRET is invalid” error message' do
          expect(response.body).to include('Le format du numéro TAHITI est invalide.')
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

        it 'displays a “API is unavailable” error message' do
          expect(response.body).to include('Désolé, la récupération des informations des numéros TAHITI est temporairement indisponible. Veuillez réessayer dans quelques instants.')
        end
      end

      context 'when the API is unavailable due to an api maintenance or pb' do
        let(:siret) { '82161143100015' }
        let(:api_etablissement_status) { 502 }

        before do
          expect(APIEntrepriseService).to receive(:api_insee_up?).and_return(false)
        end

        subject! { get :show, params: params, format: :turbo_stream }

        it 'saves the etablissement in degraded mode and SIRET on the model' do
          champ.reload
          expect(champ.etablissement.siret).to eq(siret)
          expect(champ.etablissement.as_degraded_mode?).to be true
        end

        it 'displays a “API entreprise down” error message' do
          expect(response.body).to include('Notre fournisseur de données semble en panne, nous récupérerons les données plus tard.')
        end
      end

      context 'when the SIRET is valid but unknown' do
        let(:siret) { '00000000000000' }
        let(:api_etablissement_status) { 404 }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the etablissement on the model' do
          expect(champ.reload.etablissement).to be_nil
        end

        it 'displays a “SIRET not found” error message' do
          expect(response.body).to include('Nous n’avons pas trouvé d’établissement correspondant à ce numéro TAHITI.')
        end
      end

      context 'when the Numéro TAHITI is valid but unknown', vcr: { cassette_name: 'pf_api_entreprise_not_found' } do
        let(:siret) { '111111' }
        let(:api_etablissement_status) { 404 }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the etablissement and SIRET on the model' do
          expect(champ.etablissement).to be_nil
        end

        it 'displays a “SIRET not found” error message' do
          expect(response.body).to include('Nous n’avons pas trouvé d’établissement correspondant à ce numéro TAHITI.')
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

      context 'when the Numero Tahiti informations are retrieved successfully', vcr: { cassette_name: 'pf_api_entreprise' } do
        let(:siret) { '075390001' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'populates the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.etablissement.siret).to eq(siret)
          expect(champ.reload.etablissement.naf).to eq("6419Z")
          expect(dossier.reload.etablissement).to eq(nil)
        end
      end

      context 'when the Numero Tahiti informations are retrieved successfully but without numero etablissement', vcr: { cassette_name: 'pf_api_entreprise' } do
        let(:siret) { '075390' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'does not populates the etablissement and SIRET on the model' do
          expect(champ.reload.etablissement).to eq(nil)
          expect(dossier.reload.etablissement).to eq(nil)
        end
      end
    end

    context 'when user is not signed in' do
      subject! { get :show, params: { champ_id: champ.id }, format: :turbo_stream }

      it { expect(response).to redirect_to(new_user_session_path) }
    end
  end
end
