require 'spec_helper'

describe ApiAdresse::AddressRetriever do
  describe '#list' do
    let(:request) { 'Paris' }
    let(:response) { File.open('spec/support/files/ban_address_search.json') }
    let(:status) { 200 }

    subject { described_class.new(request).list }

    before do
      stub_request(:get, "https://api-adresse.data.gouv.fr/search?&q=#{request}&limit=5")
        .to_return(status: status, body: response, headers: {})
    end

    context 'when address return a list of address' do
      it { expect(subject.size).to eq 5 }
      it { is_expected.to be_an_instance_of Array }
    end

    context 'when address return an empty list' do
      let(:response) { File.open('spec/support/files/ban_address_search_no_result.json') }

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
