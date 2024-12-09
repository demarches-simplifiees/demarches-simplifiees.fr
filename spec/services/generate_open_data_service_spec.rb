# frozen_string_literal: true

describe GenerateOpenDataService do
  describe '#months_to_query' do
    let(:default_csv) { CSV::Table.new([], headers: ["mois", "nb_comptes_crees_par_mois"]) }
    subject { described_class.months_to_query(csv) }

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
  end
end
