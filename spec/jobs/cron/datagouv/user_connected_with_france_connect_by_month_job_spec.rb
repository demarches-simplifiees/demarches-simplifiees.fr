# frozen_string_literal: true

RSpec.describe Cron::Datagouv::UserConnectedWithFranceConnectByMonthJob, type: :job do
  describe 'data_for' do
    let(:month) { Date.parse('01/01/2024') }

    subject { Cron::Datagouv::UserConnectedWithFranceConnectByMonthJob.new.send(:data_for, month:) }

    context 'when users have been france connected during the target month' do
      let!(:user) { create(:user, created_at: Date.parse('15/01/2024'), loged_in_with_france_connect: "particulier") }

      it { is_expected.to eq(['2024-01', 1]) }
    end

    context 'when users have been france connected but not during the target month' do
      let!(:user) { create(:user, created_at: Date.parse('15/12/2023'), loged_in_with_france_connect: "particulier") }

      it { is_expected.to eq(['2024-01', 0]) }
    end

    context 'when users have not been france connected' do
      let!(:user) { create(:user, created_at: Date.parse('15/01/2024'), loged_in_with_france_connect: nil) }

      it { is_expected.to eq(['2024-01', 0]) }
    end
  end
end
