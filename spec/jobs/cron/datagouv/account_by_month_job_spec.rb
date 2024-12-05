# frozen_string_literal: true

RSpec.describe Cron::Datagouv::AccountByMonthJob, type: :job do
  let(:status) { 200 }
  let(:body) { "ok" }

  describe 'perform' do
    subject { Cron::Datagouv::AccountByMonthJob.perform_now }

    it 'sends the correct CSV file to datagouv API' do
      # we simulate the case where there is no existing file
      allow(APIDatagouv::API).to receive(:existing_file_url).and_return(nil)

      allow(APIDatagouv::API).to receive(:upload_csv) do |file_name, csv_table, dataset, resource|
        csv = CSV.parse(csv_table.to_csv, headers: true)

        expect(csv.first['mois']).to eq(Date.today.prev_month.strftime("%Y-%m"))
        expect(csv.first['nb_comptes_crees_par_mois']).to eq('0')
      end

      subject
    end
  end

  describe 'data_of_range' do
    let(:range) { Date.parse('01/01/2024').all_month }

    subject { Cron::Datagouv::AccountByMonthJob.new.send(:data_of_range, range) }

    context 'when users have been created during the target month' do
      let!(:user) { create(:user, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 1]) }
    end

    context 'when users have not been created during the target month' do
      let!(:user) { create(:user, created_at: Date.parse('15/12/2023')) }

      it { is_expected.to eq(['2024-01', 0]) }
    end
  end

  describe 'months_to_query' do
    let(:default_csv) { CSV::Table.new([], headers: ["mois", "nb_comptes_crees_par_mois"]) }
    subject { Cron::Datagouv::AccountByMonthJob.new.send(:months_to_query, csv) }

    before { Timecop.freeze(Time.zone.parse('15/02/2024')) }

    context 'when there is no existing data' do
      let(:csv) { default_csv }

      it { is_expected.to eq([Date.parse('01/01/2024').all_month]) }
    end

    context 'when there is existing data from last month' do
      let(:csv) { default_csv << [Date.parse('01/01/2024').strftime("%Y %B"), 1] }

      it { is_expected.to eq([]) }
    end

    context 'when there is existing data before last month' do
      let(:csv) { default_csv << [Date.parse('01/12/2023').strftime("%Y %B"), 1] }

      it { is_expected.to eq([Date.parse('01/01/2024').all_month]) }
    end

    context 'when there is existing data in the future' do
      let(:csv) { default_csv << [Date.parse('01/06/2024').strftime("%Y %B"), 1] }

      it { is_expected.to eq([]) }
    end
  end
end
