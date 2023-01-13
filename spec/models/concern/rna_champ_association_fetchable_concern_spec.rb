RSpec.describe RNAChampAssociationFetchableConcern do
  describe '.fetch_association!' do
    let!(:champ) { create(:champ_rna, data: "not nil data") }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\//)
        .to_return(body: body, status: status)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    subject(:fetch_association!) { champ.fetch_association!(rna) }

    shared_examples "an association fetcher" do |expected_result, _expected_value, expected_data|
      it { expect(fetch_association!).to eq(expected_result) }

      it { expect { fetch_association! }.to change { champ.reload.value }.to(rna) }

      it { expect { fetch_association! }.to change { champ.reload.data }.to(expected_data) }
    end

    context 'when the RNA is empty' do
      let(:rna) { '' }
      let(:status) { 422 }
      let(:body) { '' }

      it_behaves_like "an association fetcher", nil, '', {}
    end

    context 'when the RNA is invalid' do
      let(:rna) { '1234' }
      let(:status) { 422 }
      let(:body) { '' }

      it_behaves_like "an association fetcher", nil, '1234', nil
    end

    context 'when the RNA is unknow' do
      let(:rna) { 'W111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it_behaves_like "an association fetcher", nil, 'W111111111', {}
    end

    context 'when the API is unavailable due to network error' do
      let(:rna) { 'W595001988' }
      let(:status) { 503 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }

      before { expect(APIEntrepriseService).to receive(:api_up?).and_return(false) }

      it_behaves_like "an association fetcher", :network_error, 'W595001988', nil
    end

    context 'when the RNA informations are retrieved successfully' do
      let(:rna) { 'W595001988' }
      let(:status) { 200 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }

      it_behaves_like "an association fetcher", nil, 'W595001988', {
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
  end
end
