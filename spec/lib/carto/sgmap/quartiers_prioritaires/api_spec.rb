require 'spec_helper'

describe CARTO::SGMAP::QuartiersPrioritaires::API do
  describe '.search_qp' do
    subject { described_class.search_qp(geojson) }

    before do
      stub_request(:post, "https://apicarto.sgmap.fr/quartiers-prioritaires/search").
          with(:body => /.*/,
               :headers => {'Content-Type'=>'application/json'}).
          to_return(status: status, body: body)
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
      let(:geojson) { File.read('spec/support/files/geojson/request.json') }
      let(:status) { 200 }
      let(:body) { 'toto' }

      it 'returns response body' do
        expect(subject).to eq(body)
      end

      context 'when geojson is at format JSON' do
        let(:geojson) { JSON.parse(File.read('spec/support/files/geojson/request.json')) }

        it 'returns response body' do
          expect(subject).to eq(body)
        end
      end
    end
  end
end
