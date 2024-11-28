# frozen_string_literal: true

RSpec.describe Cron::Datagouv::AccountByMonthJob, type: :job do
  AccountByMonthJob = Cron::Datagouv::AccountByMonthJob

  def format(date) = date.strftime(AccountByMonthJob::DATE_FORMAT)

  describe 'perform' do
    before { allow(APIDatagouv::API).to receive(:existing_csv).and_return(existing_csv) }

    subject(:sent_csv) do
      table = nil
      allow(APIDatagouv::API).to receive(:upload_csv) { |_, sent, _, _| table = sent }

      AccountByMonthJob.perform_now

      table
    end

    context 'when there is no existing csv' do
      let(:existing_csv) { nil }

      it 'sends a csv with one row from the previous month' do
        expect(sent_csv.first['mois']).to eq(format(1.month.ago.beginning_of_month.to_date))
        expect(sent_csv.first['nb_comptes_crees_par_mois']).to eq(0)
      end
    end

    context 'when 2 months are missing' do
      before { Timecop.freeze(Time.zone.parse('15/02/2024')) }

      let(:existing_csv) do
        csv = CSV::Table.new([], headers: AccountByMonthJob::HEADERS)
        csv << [format(Date.parse('01/10/2023')), 10]
        csv << [format(Date.parse('01/11/2023')), 11]
      end

      it 'sends a csv with one row from the previous month' do
        expected_csv = [
          ["mois", "nb_comptes_crees_par_mois"],
          ["2023-10", 10],
          ["2023-11", 11],
          ["2023-12", 0],
          ["2024-01", 0]
        ]
        expect(sent_csv.to_a).to eq(expected_csv)
      end
    end
  end

  describe 'data_for' do
    let(:month) { Date.parse('01/01/2024') }

    subject { AccountByMonthJob.new.send(:data_for, month:) }

    context 'when users have been created during the target month' do
      let!(:user) { create(:user, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 1]) }
    end

    context 'when users have not been created during the target month' do
      let!(:user) { create(:user, created_at: Date.parse('15/12/2023')) }

      it { is_expected.to eq(['2024-01', 0]) }
    end
  end

  describe 'missing_months' do
    let(:default_csv) { CSV::Table.new([], headers: ["mois", "nb_comptes_crees_par_mois"]) }
    subject { AccountByMonthJob.new.send(:missing_months, csv) }

    before { Timecop.freeze(Time.zone.parse('15/02/2024')) }

    context 'when there is no existing data' do
      let(:csv) { default_csv }

      it { is_expected.to eq([Date.parse('01/01/2024')]) }
    end

    context 'when there is existing data from last month' do
      let(:csv) { default_csv << [format(Date.parse('01/01/2024')), 1] }

      it { is_expected.to eq([]) }
    end

    context 'when there is existing data before last month' do
      let(:csv) { default_csv << [format(Date.parse('01/12/2023')), 1] }

      it { is_expected.to eq([Date.parse('01/01/2024')]) }
    end

    context 'when there is existing data in the future' do
      let(:csv) { default_csv << [format(Date.parse('01/06/2024')), 1] }

      it { is_expected.to eq([]) }
    end
  end
end