require 'spec_helper'

describe CARTO::SGMAP::QuartierPrioritaireAdapter do
  subject { described_class.new(coordinates).to_params }

  before do
    stub_request(:post, "https://apicarto.sgmap.fr/quartiers-prioritaires/search").
        with(:body => /.*/,
             :headers => {'Content-Type' => 'application/json'}).
        to_return(status: status, body: body)
  end

  context 'coordinates ard informed' do
    let(:coordinates) { '' }
    let(:status) { 200 }
    let(:body) { File.read('spec/support/files/geojson/response.json') }

    it { expect(subject).to be_a_instance_of(Hash) }

    context 'Attributs' do
      let(:qp_code) { 'QP057019' }
      it { expect(subject[qp_code][:code]).to eq(qp_code) }
      it { expect(subject[qp_code][:nom]).to eq('Hauts De Vallières') }
      it { expect(subject[qp_code][:commune]).to eq('Metz') }

      it { expect(subject[qp_code][:geometry]).to eq({:type=>"MultiPolygon", :coordinates=>[[[[6.2136923480551, 49.1342109827851], [6.21416055031881, 49.1338823553928]]]]}) }
    end
  end

  context 'coordinates are empty' do
    let(:coordinates) { '' }
    let(:status) { 404 }
    let(:body) { '' }

    it { expect { subject }.to raise_error(RestClient::ResourceNotFound) }
  end
end
