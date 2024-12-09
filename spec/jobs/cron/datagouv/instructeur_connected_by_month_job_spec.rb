# frozen_string_literal: true

RSpec.describe Cron::Datagouv::InstructeurConnectedByMonthJob, type: :job do
  let(:status) { 200 }
  let(:body) { "ok" }

  describe 'perform' do
    subject { Cron::Datagouv::InstructeurConnectedByMonthJob.perform_now }

    it 'sends the correct CSV file to datagouv API' do
      # we simulate the case where there is no existing file
      allow(APIDatagouv::API).to receive(:existing_file_url).and_return(nil)

      allow(APIDatagouv::API).to receive(:upload_csv) do |_, csv_table, _, _|
        csv = CSV.parse(csv_table.to_csv, headers: true)

        expect(csv.first['mois']).to eq(Date.today.prev_month.strftime("%Y-%m"))
        expect(csv.first['nb_instructeurs_connectes_par_mois']).to eq('0')
      end

      subject
    end
  end

  describe 'data_of_range' do
    let(:range) { Date.parse('01/01/2024').all_month }

    subject { Cron::Datagouv::InstructeurConnectedByMonthJob.new.send(:data_of_range, range) }

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
