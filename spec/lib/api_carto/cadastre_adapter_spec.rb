require 'spec_helper'

describe ApiCarto::CadastreAdapter do
  subject { described_class.new(coordinates).results }

  before do
    stub_request(:post, "https://apicarto.sgmap.fr/cadastre/geometrie")
      .with(:body => /.*/,
        :headers => { 'Content-Type' => 'application/json' })
      .to_return(status: status, body: body)
  end

  context 'coordinates are filled' do
    let(:coordinates) { '[[2.252728, 43.27151][2.323223, 32.835332]]' }
    let(:status) { 200 }
    let(:body) { File.read('spec/fixtures/files/api_carto/response_cadastre.json') }

    it { expect(subject).to be_a_instance_of(Array) }
    it { expect(subject.size).to eq(16) }

    describe 'Attribut filter' do
      let(:adapter) { described_class.new(coordinates) }
      subject { adapter.filter_properties(adapter.data_source[:features].first[:properties]) }

      it { expect(subject.size).to eq(9) }
      it do
        expect(subject.keys).to eq([
          :surface_intersection,
          :surface_parcelle,
          :numero,
          :feuille,
          :section,
          :code_dep,
          :nom_com,
          :code_com,
          :code_arr
        ])
      end
    end

    describe 'Attributes' do
      subject { super().first }

      it { expect(subject[:surface_intersection]).to eq('0.0202') }
      it { expect(subject[:surface_parcelle]).to eq(220.0664659755941) }
      it { expect(subject[:numero]).to eq('0082') }
      it { expect(subject[:feuille]).to eq(1) }
      it { expect(subject[:section]).to eq('0J') }
      it { expect(subject[:code_dep]).to eq('94') }
      it { expect(subject[:nom_com]).to eq('Maisons-Alfort') }
      it { expect(subject[:code_com]).to eq('046') }
      it { expect(subject[:code_arr]).to eq('000') }

      it { expect(subject[:geometry]).to eq({ type: "MultiPolygon", coordinates: [[[[2.4362443, 48.8092078], [2.436384, 48.8092043], [2.4363802, 48.8091414]]]] }) }
    end
  end

  context 'coordinates are empty' do
    let(:coordinates) { '' }
    let(:status) { 404 }
    let(:body) { '' }

    it { expect { subject }.to raise_error(RestClient::ResourceNotFound) }
  end
end
