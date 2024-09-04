# frozen_string_literal: true

describe ASN1::Timestamp do
  let(:asn1timestamp) { File.read('spec/fixtures/files/bill_signature/signature.der') }

  describe '.timestamp_time' do
    subject { described_class.signature_time(asn1timestamp) }

    it { is_expected.to eq Time.zone.parse('2022-12-06 09:11:17Z') }
  end

  describe '.timestamp_signed_data' do
    subject { described_class.signed_digest(asn1timestamp) }

    let(:data) { Digest::SHA256.hexdigest('{"1":"hash1","2":"hash2"}') }

    it { is_expected.to eq data }
  end
end
