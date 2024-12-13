# frozen_string_literal: true

RSpec.describe Cron::Datagouv::BaseJob, type: :job do
  def format(date) = date.strftime(Cron::Datagouv::BaseJob::DATE_FORMAT)

  describe 'missing_months' do
    let(:default_csv) { CSV::Table.new([], headers: ["mois", "nb"]) }
    subject { Cron::Datagouv::BaseJob.new.send(:missing_months, csv) }

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