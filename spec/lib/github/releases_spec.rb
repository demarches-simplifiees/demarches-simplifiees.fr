require 'spec_helper'

describe Github::Releases do

  describe '.latest' do

    subject { described_class.latest }

    context 'when github is up', vcr: {cassette_name: 'github_lastrelease'} do
      it { expect(subject.url).to eq 'https://api.github.com/repos/sgmap/tps/releases/4685573' }
      it { expect(subject.body).to match /.*[Nouveautés].*/ }
      it { expect(subject.published_at).to match /[0-9][0-9][\/][0-9][0-9][\/][0-9][0-9][0-9][0-9]/ }
    end

    context 'when github is down' do
      before do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::Forbidden)
      end

      it { is_expected.to be_nil }
    end
  end
end