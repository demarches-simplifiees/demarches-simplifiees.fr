# frozen_string_literal: true

RSpec.describe Cron::OperationsSignatureJob, type: :job do
  describe 'perform' do
    subject { Cron::OperationsSignatureJob.perform_now }

    let(:today) { Time.zone.parse('2018-01-05 00:06:00') }

    before do
      travel_to(today)
      allow(BillSignatureService).to receive(:sign_operations)
    end

    context "with dol without signature executed_at two_days_ago" do
      let(:two_days_ago_00_30) { Time.zone.parse('2018-01-03 00:30:00') }
      let(:two_days_ago_00_00) { Time.zone.parse('2018-01-03 00:00:00') }

      let(:one_day_ago_00_30) { Time.zone.parse('2018-01-04 00:30:00') }
      let(:one_day_ago_00_00) { Time.zone.parse('2018-01-04 00:00:00') }

      let!(:dol_1) { create(:dossier_operation_log, executed_at: two_days_ago_00_30) }
      let!(:dol_2) { create(:dossier_operation_log, executed_at: one_day_ago_00_30) }

      before { subject }

      it do
        expect(BillSignatureService).to have_received(:sign_operations).exactly(2).times
        expect(BillSignatureService).to have_received(:sign_operations).with([dol_1], two_days_ago_00_00)
        expect(BillSignatureService).to have_received(:sign_operations).with([dol_2], one_day_ago_00_00)
      end
    end

    context "with dol without signature executed_at today past midnight" do
      let(:today_00_01) { Time.zone.parse('2018-01-05 00:00:01') }
      let!(:dol) { create(:dossier_operation_log, executed_at: today_00_01) }

      before { subject }

      it { expect(BillSignatureService).not_to have_received(:sign_operations) }
    end
  end
end
