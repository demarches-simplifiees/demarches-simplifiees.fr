# frozen_string_literal: true

RSpec.describe Cron::Datagouv::InstructeurConnectedByMonthJob, type: :job do
  describe 'data_for' do
    let(:month) { Date.parse('01/01/2024') }

    subject { Cron::Datagouv::InstructeurConnectedByMonthJob.new.send(:data_for, month:) }

    context 'when instructeurs have been connected during the target month' do
      let!(:user) { create(:user, last_sign_in_at: Date.parse('15/01/2024')) }
      let!(:instructeur) { create(:instructeur, user: user) }

      it { is_expected.to eq(['2024-01', 1]) }
    end

    context 'when instructeurs have not been connected during the target month' do
      let!(:user) { create(:user, last_sign_in_at: Date.parse('15/12/2023')) }
      let!(:instructeur) { create(:instructeur, user: user) }

      it { is_expected.to eq(['2024-01', 0]) }
    end
  end
end
