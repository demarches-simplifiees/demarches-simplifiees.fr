require 'spec_helper'

describe APITeFenua::PlaceAdapter do
  describe '#suggestions' do
    let(:request) { 'Snack' }
    let(:response) { File.open('spec/fixtures/files/api_te_fenua/results.json') }
    let(:status) { 200 }

    subject { described_class.new(request).suggestions }

    before do
      stub_request(:get, API_TE_FENUA_URL + "/recherche?d=0&id=&q=#{request}&sid=reqId&x=0&y=0")
        .to_return(status: status, body: response, headers: {})
    end

    context 'when address return a list of places' do
      let(:first_result) { { label: 'Snack - Moerai - Rurutu', point: [-151.336697436533, -22.4556400061971], extent: [-151.336792831641, -22.4557661428341, -151.336601293606, -22.4555065461003] } }
      it { expect(subject.size).to eq 10 }
      it { is_expected.to be_an_instance_of Array }
      it { expect(subject[0]).to eq first_result }
    end

    context 'when address return an empty list' do
      let(:response) { File.open('spec/fixtures/files/api_te_fenua/no_results.json') }

      it { expect(subject.size).to eq 0 }
      it { is_expected.to be_an_instance_of Array }
    end

    context 'when BAN is unavailable' do
      let(:status) { 503 }
      let(:response) { '' }

      it { expect(subject.size).to eq 0 }
      it { is_expected.to be_an_instance_of Array }
    end

    context 'when request is empty' do
      let(:response) { 'Missing query' }
      let(:request) { '' }

      it { expect(subject.size).to eq 0 }
      it { is_expected.to be_an_instance_of Array }
    end
  end
end
