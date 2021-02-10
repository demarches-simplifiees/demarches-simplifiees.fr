describe APICarto::API do
  describe '.search_cadastre' do
    subject { described_class.search_cadastre(geojson) }

    before do
      stub_request(:post, "https://sandbox.geo.api.gouv.fr/apicarto/cadastre/geometrie")
        .with(:body => /.*/,
          :headers => { 'Content-Type' => 'application/json' })
        .to_return(status: status, body: body)
    end
    context 'when geojson is empty' do
      let(:geojson) { '' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises APICarto::API::ResourceNotFound' do
        expect { subject }.to raise_error(APICarto::API::ResourceNotFound)
      end
    end

    context 'when geojson exist' do
      let(:geojson) { File.read('spec/fixtures/files/api_carto/request_cadastre.json') }
      let(:status) { 200 }
      let(:body) { 'toto' }

      it 'returns response body' do
        expect(subject).to eq(body)
      end

      context 'when geojson is at format JSON' do
        let(:geojson) { JSON.parse(File.read('spec/fixtures/files/api_carto/request_cadastre.json')) }

        it 'returns response body' do
          expect(subject).to eq(body)
        end
      end
    end
  end
end
