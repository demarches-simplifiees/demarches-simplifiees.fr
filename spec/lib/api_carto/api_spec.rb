require 'spec_helper'

describe ApiCarto::API do
  describe '.search_qp' do
    subject { described_class.search_qp(geojson) }

    before do
      stub_request(:post, "https://apicarto.sgmap.fr/quartiers-prioritaires/search")
        .with(:body => /.*/,
          :headers => { 'Content-Type' => 'application/json' })
        .to_return(status: status, body: body)
    end
    context 'when geojson is empty' do
      let(:geojson) { '' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises RestClient::ResourceNotFound' do
        expect { subject }.to raise_error(RestClient::ResourceNotFound)
      end
    end

    context 'when request return 500' do
      let(:geojson) { File.read('spec/fixtures/files/api_carto/request_qp.json') }
      let(:status) { 500 }
      let(:body) { 'toto' }

      it 'raises RestClient::ResourceNotFound' do
        expect { subject }.to raise_error(RestClient::ResourceNotFound)
      end
    end

    context 'when geojson exist' do
      let(:geojson) { File.read('spec/fixtures/files/api_carto/request_qp.json') }
      let(:status) { 200 }
      let(:body) { 'toto' }

      it 'returns response body' do
        expect(subject).to eq(body)
      end

      context 'when geojson is at format JSON' do
        let(:geojson) { JSON.parse(File.read('spec/fixtures/files/api_carto/request_qp.json')) }

        it 'returns response body' do
          expect(subject).to eq(body)
        end
      end
    end
  end

  describe '.search_cadastre' do
    subject { described_class.search_cadastre(geojson) }

    before do
      stub_request(:post, "https://apicarto.sgmap.fr/cadastre/geometrie")
        .with(:body => /.*/,
          :headers => { 'Content-Type' => 'application/json' })
        .to_return(status: status, body: body)
    end
    context 'when geojson is empty' do
      let(:geojson) { '' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises RestClient::ResourceNotFound' do
        expect { subject }.to raise_error(RestClient::ResourceNotFound)
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
