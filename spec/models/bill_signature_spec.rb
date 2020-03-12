RSpec.describe BillSignature, type: :model do
  describe 'validations' do
    subject(:bill_signature) { build(:bill_signature) }

    describe 'check_bill_digest' do
      before do
        bill_signature.dossier_operation_logs = dossier_operation_logs
        bill_signature.digest = digest
        bill_signature.valid?
      end

      context 'when there are no operations' do
        let(:dossier_operation_logs) { [] }

        context 'when the digest is correct' do
          let(:digest) { Digest::SHA256.hexdigest('{}') }

          it { expect(bill_signature.errors.details[:digest]).to be_empty }
        end

        context 'when the digest is incorrect' do
          let(:digest) { 'baadf00d' }

          it { expect(bill_signature.errors.details[:digest]).to eq [error: :invalid] }
        end
      end

      context 'when the signature has operations' do
        let(:dossier_operation_logs) { [build(:dossier_operation_log, id: '1234', digest: 'abcd')] }

        context 'when the digest is correct' do
          let(:digest) { Digest::SHA256.hexdigest('{"1234":"abcd"}') }

          it { expect(bill_signature.errors.details[:digest]).to be_empty }
        end

        context 'when the digest is incorrect' do
          let(:digest) { 'baadf00d' }

          it { expect(bill_signature.errors.details[:digest]).to eq [error: :invalid] }
        end
      end
    end

    describe 'check_serialized_bill_contents' do
      before do
        bill_signature.dossier_operation_logs = dossier_operation_logs
        bill_signature.serialized.attach(io: StringIO.new(serialized), filename: 'file') if serialized.present?
        bill_signature.valid?
      end

      context 'when there are no operations' do
        let(:dossier_operation_logs) { [] }
        let(:serialized) { '{}' }

        it { expect(bill_signature.errors.details[:serialized]).to be_empty }
      end

      context 'when the signature has operations' do
        let(:dossier_operation_logs) { [build(:dossier_operation_log, id: '1234', digest: 'abcd')] }
        let(:serialized) { '{"1234":"abcd"}' }

        it { expect(bill_signature.errors.details[:serialized]).to be_empty }
      end

      context 'when serialized isn’t set' do
        let(:dossier_operation_logs) { [] }
        let(:serialized) { nil }

        it { expect(bill_signature.errors.details[:serialized]).to eq [error: :blank] }
      end
    end

    describe 'check_signature_contents' do
      before do
        bill_signature.signature.attach(io: StringIO.new(signature), filename: 'file') if signature.present?
        allow(ASN1::Timestamp).to receive(:signature_time).and_return(signature_time)
        allow(ASN1::Timestamp).to receive(:signed_digest).and_return(signed_digest)
        bill_signature.digest = digest
        bill_signature.valid?
      end

      context 'when the signature is correct' do
        let(:signature) { 'signature' }
        let(:signature_time) { 1.day.ago }
        let(:digest) { 'abcd' }
        let(:signed_digest) { 'abcd' }

        it { expect(bill_signature.errors.details[:signature]).to be_empty }
      end

      context 'when the signature isn’t set' do
        let(:signature) { nil }
        let(:signature_time) { 1.day.ago }
        let(:digest) { 'abcd' }
        let(:signed_digest) { 'abcd' }

        it { expect(bill_signature.errors.details[:signature]).to eq [error: :blank] }
      end

      context 'when the signature time is in the future' do
        let(:signature) { 'signature' }
        let(:signature_time) { 1.day.from_now }
        let(:digest) { 'abcd' }
        let(:signed_digest) { 'abcd' }

        it { expect(bill_signature.errors.details[:signature]).to eq [error: :invalid_date] }
      end

      context 'when the signature doesn’t match the digest' do
        let(:signature) { 'signature' }
        let(:signature_time) { 1.day.ago }
        let(:digest) { 'abcd' }
        let(:signed_digest) { 'dcba' }

        it { expect(bill_signature.errors.details[:signature]).to eq [error: :invalid] }
      end
    end
  end

  describe '.build_with_operations' do
    let(:day) { Date.new(1871, 03, 18) }
    subject(:bill_signature) { build(:bill_signature, :with_signature) }

    before do
      bill_signature.dossier_operation_logs = dossier_operation_logs
      bill_signature.serialize_operations(day)
    end

    context 'when there are no operations' do
      let(:dossier_operation_logs) { [] }

      it { expect(bill_signature.operations_bill).to eq({}) }
      it { expect(bill_signature.digest).to eq(Digest::SHA256.hexdigest('{}')) }
      it { expect(bill_signature.read_serialized).to eq('{}') }
      it { expect(bill_signature.serialized.filename).to eq('demarches-simplifiees-operations-1871-03-18.json') }
    end

    context 'when there is one operation' do
      let(:dossier_operation_logs) do
        [build(:dossier_operation_log, id: '1234', digest: 'abcd')]
      end

      it { expect(bill_signature.operations_bill).to eq({ '1234' => 'abcd' }) }
      it { expect(bill_signature.digest).to eq(Digest::SHA256.hexdigest('{"1234":"abcd"}')) }
      it { expect(bill_signature.read_serialized).to eq('{"1234":"abcd"}') }
      it { expect(bill_signature.serialized.filename).to eq('demarches-simplifiees-operations-1871-03-18.json') }
    end

    context 'when there are several operations' do
      let(:dossier_operation_logs) do
        [
          build(:dossier_operation_log, id: '1234', digest: 'abcd'),
          build(:dossier_operation_log, id: '5678', digest: 'dcba')
        ]
      end

      it { expect(bill_signature.operations_bill).to eq({ '1234' => 'abcd', '5678' => 'dcba' }) }
      it { expect(bill_signature.digest).to eq(Digest::SHA256.hexdigest('{"1234":"abcd","5678":"dcba"}')) }
      it { expect(bill_signature.read_serialized).to eq('{"1234":"abcd","5678":"dcba"}') }
      it { expect(bill_signature.serialized.filename).to eq('demarches-simplifiees-operations-1871-03-18.json') }
    end
  end
end
