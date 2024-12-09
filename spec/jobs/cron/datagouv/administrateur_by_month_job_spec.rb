# frozen_string_literal: true

RSpec.describe Cron::Datagouv::AdministrateurByMonthJob, type: :job do
  def format(date) = date.strftime(AdministrateurByMonthJob::DATE_FORMAT)

  describe 'data_for' do
    let(:month) { Date.parse('01/01/2024') }

    subject { Cron::Datagouv::AdministrateurByMonthJob.new.send(:data_for, month:) }

    context 'when administrateurs have been created during the target month' do
      let!(:administrateur) { create(:administrateur, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 1]) }
    end

    context 'when administrateurs have not been created during the target month' do
      let!(:administrateur) { create(:administrateur, created_at: Date.parse('15/12/2023')) }

      it { is_expected.to eq(['2024-01', 0]) }
    end
  end
end
