require 'spec_helper'

describe CARTO::SGMAP::QuartiersPrioritaires::Adapter do
  subject { described_class.new(coordinates).to_params }

  before do
    stub_request(:post, "https://apicarto.sgmap.fr/quartiers-prioritaires/search")
      .with(:body => /.*/,
        :headers => { 'Content-Type' => 'application/json' })
      .to_return(status: status, body: body)
  end

  context 'coordinates are filled' do
    let(:coordinates) { '[[2.252728, 43.27151][2.323223, 32.835332]]' }
    let(:status) { 200 }
    let(:body) { File.read('spec/support/files/geojson/response_qp.json') }

    it { expect(subject).to be_a_instance_of(Hash) }

    context 'Attributes' do
      let(:qp_code) { 'QP057019' }

      subject { super()[qp_code] }

      it { expect(subject[:code]).to eq(qp_code) }
      it { expect(subject[:nom]).to eq('Hauts De Vallières') }
      it { expect(subject[:commune]).to eq('Metz') }

      it { expect(subject[:geometry]).to eq({ :type => "MultiPolygon", :coordinates => [[[[6.2136923480551, 49.1342109827851], [6.21416055031881, 49.1338823553928]]]] }) }
    end
  end

  context 'coordinates are empty' do
    let(:coordinates) { '' }
    let(:status) { 404 }
    let(:body) { '' }

    it { expect { subject }.to raise_error(RestClient::ResourceNotFound) }
  end
end
