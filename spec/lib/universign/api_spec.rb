# frozen_string_literal: true

describe Universign::API do
  describe '.request_timestamp', vcr: { cassette_name: 'universign' } do
    subject { described_class.timestamp(digest) }

    let(:digest) { Digest::SHA256.hexdigest("CECI EST UN HASH") }

    before do
      stub_const("UNIVERSIGN_API_URL", "https://ws.universign.eu/tsa/post/")
    end

    it { is_expected.not_to be_nil }
  end
end
