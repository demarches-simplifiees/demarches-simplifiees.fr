require 'spec_helper'

describe ApiCarto::QuartiersPrioritaires::Adapter do
  subject { described_class.new(coordinates).results }

  before do
    stub_request(:post, "https://apicarto.sgmap.fr/quartiers-prioritaires/search")
      .with(:body => /.*/,
        :headers => { 'Content-Type' => 'application/json' })
      .to_return(status: status, body: body)
  end

  context 'coordinates are filled' do
    let(:coordinates) { '[[2.252728, 43.27151][2.323223, 32.835332]]' }
    let(:status) { 200 }
    let(:body) { File.read('spec/support/files/api_carto/response_qp.json') }

    it { expect(subject).to be_a_instance_of(Array) }

    context 'Attributes' do
      let(:qp_code) { 'QP057019' }

      it { expect(subject.first[:code]).to eq(qp_code) }
      it { expect(subject.first[:nom]).to eq('Hauts De Vallières') }
      it { expect(subject.first[:commune]).to eq('Metz') }

      it { expect(subject.first[:geometry]).to eq({ :type => "MultiPolygon", :coordinates => [[[[6.2136923480551, 49.1342109827851], [6.21416055031881, 49.1338823553928]]]] }) }
    end
  end

  context 'coordinates are empty' do
    let(:coordinates) { '' }
    let(:status) { 404 }
    let(:body) { '' }

    it { expect { subject }.to raise_error(RestClient::ResourceNotFound) }
  end
end
