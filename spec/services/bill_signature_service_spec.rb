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
end
