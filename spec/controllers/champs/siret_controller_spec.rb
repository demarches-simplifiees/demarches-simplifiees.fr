describe Champs::SiretController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published) }

  describe '#show' do
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }
    let(:champ) do
      d = dossier
      type_de_champ = create(:type_de_champ_siret, procedure: procedure)
      type_de_champ.champ.create(dossier: d, value: nil, etablissement: nil)
    end
    let(:params) do
      {
        champ_id: champ.id,
        dossier: {
          champs_attributes: {
            '1' => { value: siret.to_s }
          }
        },
        position: '1'
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
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*token=/)
          .to_return(status: api_etablissement_status, body: api_etablissement_body)
        allow_any_instance_of(ApiEntrepriseToken).to receive(:roles)
          .and_return(["attestations_fiscales", "attestations_sociales", "bilans_entreprise_bdf"])
        allow_any_instance_of(ApiEntrepriseToken).to receive(:expired?).and_return(token_expired)
      end

      context 'when the SIRET is empty' do
        subject! { get :show, params: params, format: 'js' }

        it 'clears the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end

        it 'clears any information or error message' do
          expect(response.body).to include('.siret-info-1')
          expect(response.body).to include('innerHTML = ""')
        end
      end

      context 'when the SIRET is invalid' do
        let(:siret) { '1234' }

        subject! { get :show, params: params, format: 'js' }

        it 'clears the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end

        it 'displays a “SIRET is invalid” error message' do
          expect(response.body).to include("Le numéro TAHITI doit comporter exactement #{SIRET_LENGTH} caractères.")
        end
      end

      context 'when the API is unavailable' do
        let(:siret) { '82161143100015' }
        let(:api_etablissement_status) { 503 }

        subject! { get :show, params: params, format: 'js' }

        it 'clears the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end

        it 'displays a “API is unavailable” error message' do
          expect(response.body).to include(I18n.t('errors.messages.siret_network_error'))
        end
      end

      context 'when the SIRET is valid but unknown' do
        let(:siret) { '0' * SIRET_LENGTH }
        let(:api_etablissement_status) { 404 }

        subject! { get :show, params: params, format: 'js' }

        it 'clears the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end

        it 'displays a “SIRET not found” error message' do
          expect(response.body).to include('Nous n’avons pas trouvé d’établissement correspondant à ce numéro TAHITI.')
        end
      end

      context 'when the SIRET informations are retrieved successfully' do
        let(:siret) { '41816609600051' }
        let(:api_etablissement_status) { 200 }
        let(:api_etablissement_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }

        subject! { get :show, params: params, format: 'js' }

        it 'populates the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.value).to eq(siret)
          expect(champ.etablissement.siret).to eq(siret)
          expect(champ.reload.etablissement.naf).to eq("6202A")
          expect(dossier.reload.etablissement).to eq(nil)
        end
      end
    end

    context 'when user is not signed in' do
      subject! { get :show, params: { position: '1' }, format: 'js' }

      it { expect(response.code).to eq('401') }
    end
  end
end
