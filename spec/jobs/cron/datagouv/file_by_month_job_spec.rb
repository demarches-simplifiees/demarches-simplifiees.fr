# frozen_string_literal: true

RSpec.describe Cron::Datagouv::FileByMonthJob, type: :job do
  describe 'data_for' do
    let(:month) { Date.parse('01/01/2024') }

    subject { Cron::Datagouv::FileByMonthJob.new.send(:data_for, month:) }

    context 'when dossiers have been created during the target month' do
      let!(:dossier) { create(:dossier, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 1]) }
    end

    context 'when dossiers have not been created during the target month' do
      let!(:dossier) { create(:dossier, created_at: Date.parse('15/12/2023')) }

      it { is_expected.to eq(['2024-01', 0]) }
    end
  end
end
