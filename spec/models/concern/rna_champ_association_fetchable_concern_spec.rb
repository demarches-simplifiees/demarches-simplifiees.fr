RSpec.describe RNAChampAssociationFetchableConcern do
  describe '.fetch_association!' do
    let!(:champ) { create(:champ_rna, data: "not nil data", value: 'W173847273') }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/djepva\/api-association\/associations\/open_data\/#{rna}/)
        .to_return(body: body, status: status)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    subject(:fetch_association!) { champ.fetch_association!(rna) }

    shared_examples "an association fetcher" do |expected_result, expected_error, expected_value, expected_data|
      it { expect { fetch_association! }.to change { champ.reload.value }.to(expected_value) }

      it { expect { fetch_association! }.to change { champ.reload.data }.to(expected_data) }

      it { expect(fetch_association!).to eq(expected_result) }

      it 'populates the association_fetch_error_key when an error occurs' do
        fetch_association!
        expect(champ.association_fetch_error_key).to eq(expected_error)
      end
    end

    context 'when the RNA is empty' do
      let(:rna) { '' }
      let(:status) { 422 }
      let(:body) { '' }

      it_behaves_like "an association fetcher", false, :empty, '', nil
    end

    context 'when the RNA is invalid' do
      let(:rna) { '1234' }
      let(:status) { 422 }
      let(:body) { '' }

      it_behaves_like "an association fetcher", false, :invalid, '1234', nil
    end

    context 'when the RNA is unknow' do
      let(:rna) { 'W111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it_behaves_like "an association fetcher", false, :not_found, 'W111111111', nil
    end

    context 'when the API is unavailable due to network error' do
      let(:rna) { 'W595001988' }
      let(:status) { 503 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }

      before { expect(APIEntrepriseService).to receive(:api_djepva_up?).and_return(false) }

      it_behaves_like "an association fetcher", false, :network_error, 'W595001988', nil
    end

    context 'when the RNA informations are retrieved successfully' do
      let(:rna) { 'W595001988' }
      let(:status) { 200 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }

      it_behaves_like "an association fetcher", true, nil, 'W595001988', {
        "association_titre" => "LA PRÉVENTION ROUTIERE",
        "association_objet" => "L'association a pour objet de promouvoir la pratique du sport de haut niveau et de contribuer à la formation des jeunes sportifs.",
        "association_date_creation" => "2015-01-01",
        "association_date_declaration" => "2019-01-01",
        "association_date_publication" => "2018-01-01",
        "association_rna" => "W751080001",
        "adresse" => {
          "complement" => "",
          "numero_voie" => "33",
          "type_voie" => "rue",
          "libelle_voie" => "de Modagor",
          "distribution" => "dummy",
          "code_insee" => "75108",
          "code_postal" => "75009",
          "commune" => "Paris"
        }
      }
    end
  end
end
