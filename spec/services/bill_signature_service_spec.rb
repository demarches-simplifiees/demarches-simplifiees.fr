describe BillSignatureService do
  describe ".grouped_unsigned_operation_until" do
    subject { BillSignatureService.grouped_unsigned_operation_until(date).length }

    let(:date) { Time.zone.now.beginning_of_day }

    context "when operations of several days need to be signed" do
      before do
        create :dossier_operation_log, executed_at: 3.days.ago
        create :dossier_operation_log, executed_at: 2.days.ago
        create :dossier_operation_log, executed_at: 1.day.ago
      end

      it { is_expected.to eq 3 }
    end

    context "when operations on a single day need to be signed" do
      before do
        create :dossier_operation_log, executed_at: 1.day.ago
        create :dossier_operation_log, executed_at: 1.day.ago
      end

      it { is_expected.to eq 1 }
    end

    context "when there are no operations to be signed" do
      before do
        create :dossier_operation_log, created_at: 1.day.ago, bill_signature: build(:bill_signature, :with_signature, :with_serialized)
        create :dossier_operation_log, created_at: 1.day.from_now
      end

      it { is_expected.to eq 0 }
    end
  end

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

    context "when everything is fine" do
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
