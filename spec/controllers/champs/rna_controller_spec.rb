describe Champs::RNAController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :rna }]) }

  describe '#show' do
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }
    let(:champ) { dossier.champs_public.first }

    let(:champs_public_attributes) do
      champ_attributes = {}
      champ_attributes[champ.public_id] = { value: rna }
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

    context 'when the user is signed in' do
      render_views

      before do
        sign_in user
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/djepva\/api-association\/associations\/open_data\/#{rna}/)
          .to_return(body: body, status: status)
        allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
      end

      context 'when the RNA is empty' do
        let(:rna) { '' }
        let(:status) { 422 }
        let(:body) { '' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the data on the model' do
          expect(champ.reload.data).to be_nil
        end

        it 'clears any information or error message' do
          expect(response.body).to include(ActionView::RecordIdentifier.dom_id(champ, :rna_info))
        end
      end

      context 'when the RNA is invalid' do
        let(:rna) { '1234' }
        let(:status) { 422 }
        let(:body) { '' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the data on the model' do
          expect(champ.reload.data).to be_nil
        end

        it 'displays a “RNA is invalid” error message' do
          expect(response.body).to include("Le numéro RNA doit commencer par un W majuscule suivi de 9 chiffres ou lettres")
        end
      end

      context 'when the RNA is unknow' do
        let(:rna) { 'W111111111' }
        let(:status) { 404 }
        let(:body) { '' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the data on the model' do
          champ.reload
          expect(champ.data).to be_nil
        end

        it 'displays a “RNA is invalid” error message' do
          expect(response.body).to include("Aucun établissement trouvé")
        end
      end

      context 'when the API is unavailable due to network error' do
        let(:rna) { 'W595001988' }
        let(:status) { 503 }
        let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }

        before do
          expect(APIEntrepriseService).to receive(:api_djepva_up?).and_return(false)
        end

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the data on the model' do
          expect(champ.reload.data).to be_nil
        end

        it 'displays a “API is unavailable” error message' do
          expect(response.body).to include("Une erreur réseau a empêché l’association liée à ce RNA d’être trouvée")
        end
      end

      context 'when the RNA informations are retrieved successfully' do
        let(:rna) { 'W595001988' }
        let(:status) { 200 }
        let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'populates the data and RNA on the model' do
          champ.reload
          expect(champ.value).to eq(rna)
          expect(champ.data["association_titre"]).to eq("LA PRÉVENTION ROUTIERE")
          expect(champ.data["association_objet"]).to eq("L'association a pour objet de promouvoir la pratique du sport de haut niveau et de contribuer à la formation des jeunes sportifs.")
          expect(champ.data["association_date_creation"]).to eq("2015-01-01")
          expect(champ.data["association_date_declaration"]).to eq("2019-01-01")
          expect(champ.data["association_date_publication"]).to eq("2018-01-01")
          expect(champ.data["association_rna"]).to eq("W751080001")
        end
      end
    end

    context 'when user is not signed in' do
      subject! { get :show, params: { champ_id: champ.id }, format: :turbo_stream }

      it { expect(response.code).to redirect_to(new_user_session_path) }
    end
  end
end
