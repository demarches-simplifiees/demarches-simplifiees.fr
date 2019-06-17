require 'rails_helper'

RSpec.describe BillSignature, type: :model do
  describe 'validations' do
    describe 'check_bill_digest' do
      before do
        subject.dossier_operation_logs = dossier_operation_logs
        subject.digest = digest
        subject.valid?
      end

      context 'no operations' do
        let(:dossier_operation_logs) { [] }

        context 'correct digest' do
          let(:digest) { Digest::SHA256.hexdigest('{}') }

          it { expect(subject.errors.details[:digest]).to be_empty }
        end

        context 'bad digest' do
          let(:digest) { 'baadf00d' }

          it { expect(subject.errors.details[:digest]).to eq [error: :invalid] }
        end
      end

      context 'operations set, good digest' do
        let(:dossier_operation_logs) { [build(:dossier_operation_log, id: '1234', digest: 'abcd')] }

        context 'correct digest' do
          let(:digest) { Digest::SHA256.hexdigest('{"1234":"abcd"}') }

          it { expect(subject.errors.details[:digest]).to be_empty }
        end

        context 'bad digest' do
          let(:digest) { 'baadf00d' }

          it { expect(subject.errors.details[:digest]).to eq [error: :invalid] }
        end
      end
    end

    describe 'check_serialized_bill_contents' do
      before do
        subject.dossier_operation_logs = dossier_operation_logs
        subject.serialized.attach(io: StringIO.new(serialized), filename: 'file') if serialized.present?
        subject.valid?
      end

      context 'no operations' do
        let(:dossier_operation_logs) { [] }
        let(:serialized) { '{}' }

        it { expect(subject.errors.details[:serialized]).to be_empty }
      end

      context 'operations set' do
        let(:dossier_operation_logs) { [build(:dossier_operation_log, id: '1234', digest: 'abcd')] }
        let(:serialized) { '{"1234":"abcd"}' }

        it { expect(subject.errors.details[:serialized]).to be_empty }
      end

      context 'serialized not set' do
        let(:dossier_operation_logs) { [] }
        let(:serialized) { nil }

        it { expect(subject.errors.details[:serialized]).to eq [error: :blank] }
      end
    end

    describe 'check_signature_contents' do
      before do
        subject.signature.attach(io: StringIO.new(signature), filename: 'file') if signature.present?
        allow(ASN1::Timestamp).to receive(:signature_time).and_return(signature_time)
        allow(ASN1::Timestamp).to receive(:signed_digest).and_return(signed_digest)
        subject.digest = digest
        subject.valid?
      end

      context 'correct signature' do
        let(:signature) { 'signature' }
        let(:signature_time) { 1.day.ago }
        let(:digest) { 'abcd' }
        let(:signed_digest) { 'abcd' }

        it { expect(subject.errors.details[:signature]).to be_empty }
      end

      context 'signature not set' do
        let(:signature) { nil }
        let(:signature_time) { 1.day.ago }
        let(:digest) { 'abcd' }
        let(:signed_digest) { 'abcd' }

        it { expect(subject.errors.details[:signature]).to eq [error: :blank] }
      end

      context 'wrong signature time' do
        let(:signature) { 'signature' }
        let(:signature_time) { 1.day.from_now }
        let(:digest) { 'abcd' }
        let(:signed_digest) { 'abcd' }

        it { expect(subject.errors.details[:signature]).to eq [error: :invalid_date] }
      end

      context 'wrong signature digest' do
        let(:signature) { 'signature' }
        let(:signature_time) { 1.day.ago }
        let(:digest) { 'abcd' }
        let(:signed_digest) { 'dcba' }

        it { expect(subject.errors.details[:signature]).to eq [error: :invalid] }
      end
    end
  end

  describe '.build_with_operations' do
    subject { described_class.build_with_operations(dossier_operation_logs, Date.new(1871, 03, 18)) }

    context 'no operations' do
      let(:dossier_operation_logs) { [] }

      it { expect(subject.operations_bill).to eq({}) }
      it { expect(subject.digest).to eq(Digest::SHA256.hexdigest('{}')) }
      it { expect(subject.serialized.download).to eq('{}') }
      it { expect(subject.serialized.filename).to eq('demarches-simplifiees-operations-1871-03-18.json') }
    end

    context 'one operation' do
      let(:dossier_operation_logs) do
        [build(:dossier_operation_log, id: '1234', digest: 'abcd')]
      end

      it { expect(subject.operations_bill).to eq({ '1234' => 'abcd' }) }
      it { expect(subject.digest).to eq(Digest::SHA256.hexdigest('{"1234":"abcd"}')) }
      it { expect(subject.serialized.download).to eq('{"1234":"abcd"}') }
      it { expect(subject.serialized.filename).to eq('demarches-simplifiees-operations-1871-03-18.json') }
    end

    context 'several operations' do
      let(:dossier_operation_logs) do
        [
          build(:dossier_operation_log, id: '1234', digest: 'abcd'),
          build(:dossier_operation_log, id: '5678', digest: 'dcba')
        ]
      end

      it { expect(subject.operations_bill).to eq({ '1234' => 'abcd', '5678' => 'dcba' }) }
      it { expect(subject.digest).to eq(Digest::SHA256.hexdigest('{"1234":"abcd","5678":"dcba"}')) }
      it { expect(subject.serialized.download).to eq('{"1234":"abcd","5678":"dcba"}') }
      it { expect(subject.serialized.filename).to eq('demarches-simplifiees-operations-1871-03-18.json') }
    end
  end
end
