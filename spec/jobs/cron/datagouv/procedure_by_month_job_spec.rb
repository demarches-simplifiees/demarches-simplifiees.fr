# frozen_string_literal: true

RSpec.describe Cron::Datagouv::ProcedureByMonthJob, type: :job do
  describe 'data_for' do
    let(:month) { Date.parse('01/01/2024') }

    subject { Cron::Datagouv::ProcedureByMonthJob.new.send(:data_for, month:) }

    context 'when procedures have been created during the target month' do
      let!(:procedure) { create(:procedure, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 1]) }
    end

    context 'when procedures have not been created during the target month' do
      let!(:procedure) { create(:procedure, created_at: Date.parse('15/12/2023')) }

      it { is_expected.to eq(['2024-01', 0]) }
    end
  end
end
