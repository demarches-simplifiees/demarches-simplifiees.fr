require 'spec_helper'

describe Github::API do

  describe '.base_uri' do
    it { expect(described_class.base_uri).to eq 'https://api.github.com' }
  end

  describe '.latest_release' do
    subject { described_class.latest_release }

    context 'when github is up', vcr: {cassette_name: 'github_lastrelease'} do
      it { expect(subject).to be_a RestClient::Response }
      it { expect(subject.code).to eq 200 }
    end

    context 'when github is down' do

      before do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::Forbidden)
      end

      it { is_expected.to be_nil }
    end
  end
end