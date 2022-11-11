describe Champs::RNAController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, :with_rna) }

  describe '#show' do
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }
    let(:champ) { dossier.champs_public.first }

    let(:champs_public_attributes) do
      champ_attributes = []
      champ_attributes[champ.id] = { value: rna }
      champ_attributes
    end
    let(:params) do
      {
        champ_id: champ.id,
        dossier: {
          champs_public_attributes: champs_public_attributes
        }
      }
    end

    context 'when the user is signed in' do
      render_views

      before do
        sign_in user
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\//)
          .to_return(body: body, status: status)
        allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
      end

      context 'when the RNA is empty' do
        let(:rna) { '' }
        let(:status) { 422 }
        let(:body) { '' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the data and value on the model' do
          champ.reload
          expect(champ.data).to eq({})
          expect(champ.value).to eq("")
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

        it 'clears the data and value on the model' do
          champ.reload
          expect(champ.data).to be_nil
          expect(champ.value).to be_nil
        end

        it 'displays a “RNA is invalid” error message' do
          expect(response.body).to include("Aucun établissement trouvé")
        end
      end

      context 'when the RNA is unknow' do
        let(:rna) { 'W111111111' }
        let(:status) { 404 }
        let(:body) { '' }

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the data on the model' do
          champ.reload
          expect(champ.data).to eq({})
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
          expect(APIEntrepriseService).to receive(:api_up?).and_return(false)
        end

        subject! { get :show, params: params, format: :turbo_stream }

        it 'clears the data and value on the model' do
          champ.reload
          expect(champ.data).to be_nil
          expect(champ.value).to be_nil
        end

        it 'displays a “API is unavailable” error message' do
          expect(response.body).to include("Une erreur réseau a empêché l&#39;association liée à ce RNA d&#39;être trouvée")
        end
      end

      context 'when the RNA informations are retrieved successfully' do
        let(:rna) { 'W595001988' }
        let(:status) { 200 }
        let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }
        let(:expected_data) do
          {
            "association_id" => "W595001988",
            "association_titre" => "UN SUR QUATRE",
            "association_objet" => "valoriser, transmettre et partager auprès des publics les plus larges possibles, les bienfaits de l'immigration, la richesse de la diversité et la curiosité de l'autre autrement",
            "association_siret" => nil,
            "association_date_creation" => "2014-01-23",
            "association_date_declaration" => "2014-01-24",
            "association_date_publication" => "2014-02-08",
            "association_date_dissolution" => "0001-01-01",
            "association_adresse_siege" => {
              "complement" => "",
              "numero_voie" => "61",
              "type_voie" => "RUE",
              "libelle_voie" => "des Noyers",
              "distribution" => "_",
              "code_insee" => "93063",
              "code_postal" => "93230",
              "commune" => "Romainville"
            },
            "association_code_civilite_dirigeant" => "PM",
            "association_civilite_dirigeant" => "Monsieur le Président",
            "association_code_etat" => "A",
            "association_etat" => "Active",
            "association_code_groupement" => "S",
            "association_groupement" => "simple",
            "association_mise_a_jour" => 1392295833,
            "association_rna" => "W595001988"
          }
        end

        subject! { get :show, params: params, format: :turbo_stream }

        it 'populates the data and RNA on the model' do
          champ.reload
          expect(champ.value).to eq(rna)
          expect(champ.data).to eq(expected_data)
        end
      end
    end

    context 'when user is not signed in' do
      subject! { get :show, params: { champ_id: champ.id }, format: :turbo_stream }

      it { expect(response.code).to eq('401') }
    end
  end
end
