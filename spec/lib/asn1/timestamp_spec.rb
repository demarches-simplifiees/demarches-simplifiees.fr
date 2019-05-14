require 'spec_helper'

describe ASN1::Timestamp do
  let(:asn1timestamp) { File.read('spec/fixtures/files/bill_signature/signature.der') }

  describe '.timestamp_time' do
    subject { described_class.signature_time(asn1timestamp) }

    it { is_expected.to eq Time.zone.parse('2019-04-30 15:30:20 UTC') }
  end

  describe '.timestamp_signed_data' do
    subject { described_class.signed_digest(asn1timestamp) }

    let(:data) { Digest::SHA256.hexdigest('CECI EST UN BLOB') }

    it { is_expected.to eq data }
  end
end
