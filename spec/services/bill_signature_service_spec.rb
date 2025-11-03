# frozen_string_literal: true

describe BillSignatureService do
  describe ".sign_operations" do
    let(:date) { Date.today }

    let(:operations_hash) { [['1', 'hash1'], ['2', 'hash2']] }
    let(:operations) do
      operations_hash
        .map { |id, digest| DossierOperationLog.new(id:, digest:, operation: 'accepter') }
    end

    let(:timestamp) { File.read('spec/fixtures/files/bill_signature/signature.der') }

    subject { BillSignatureService.sign_operations(operations, date) }

    before do
      DossierOperationLog.where(id: [1, 2]).destroy_all

      expect(Certigna::API).to receive(:timestamp).and_return(timestamp)
    end

    xcontext "when everything is fine" do
      it do
        expect { subject }.not_to raise_error
        expect(BillSignature.count).to eq(1)
      end
    end

    context "when the digest does not match with the pre recorded timestamp token" do
      let(:operations_hash) { [['1', 'hash1'], ['2', 'hash3']] }

      it do
        expect { subject }.to raise_error(/La validation a échoué : Le champ « signature » ne correspond pas à l’empreinte/)
        expect(BillSignature.count).to eq(0)
      end
    end

    context "when the timestamp token cannot be verified by openssl" do
      let(:timestamp) do
        File.read('spec/fixtures/files/bill_signature/signature.der').tap { |s| s[-1] = 'd' }
      end

      it do
        expect { subject }.to raise_error(/openssl verification failed/)
        expect(BillSignature.count).to eq(0)
      end
    end
  end
end
