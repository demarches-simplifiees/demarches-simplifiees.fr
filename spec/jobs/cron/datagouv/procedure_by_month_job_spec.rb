# frozen_string_literal: true

RSpec.describe Cron::Datagouv::ProcedureByMonthJob, type: :job do
  ProcedureByMonthJob = Cron::Datagouv::ProcedureByMonthJob

  def format(date) = date.strftime(ProcedureByMonthJob::DATE_FORMAT)

  describe 'perform' do
    before { allow(APIDatagouv::API).to receive(:existing_csv).and_return(existing_csv) }

    subject(:sent_csv) do
      table = nil
      allow(APIDatagouv::API).to receive(:upload_csv) { |_, sent, _, _| table = sent }

      ProcedureByMonthJob.perform_now

      table
    end

    context 'when there is no existing csv' do
      let(:existing_csv) { nil }

      it 'sends a csv with one row from the previous month' do
        expect(sent_csv.first['mois']).to eq(format(1.month.ago.beginning_of_month.to_date))
        expect(sent_csv.first['nb_procedures_creees_par_mois']).to eq(0)
      end
    end

    context 'when 2 months are missing' do
      before { Timecop.freeze(Time.zone.parse('15/02/2024')) }

      let(:existing_csv) do
        csv = CSV::Table.new([], headers: ProcedureByMonthJob::HEADERS)
        csv << [format(Date.parse('01/10/2023')), 10]
        csv << [format(Date.parse('01/11/2023')), 11]
      end

      it 'sends a csv with one row from the previous month' do
        expected_csv = [
          ["mois", "nb_procedures_creees_par_mois"],
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

    subject { ProcedureByMonthJob.new.send(:data_for, month:) }

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
