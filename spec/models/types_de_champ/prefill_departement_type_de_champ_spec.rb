# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillDepartementTypeDeChamp, type: :model do
  let(:type_de_champ) { build(:type_de_champ_departements) }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe 'ancestors' do
    subject { described_class.build(type_de_champ) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values', vcr: { cassette_name: 'api_geo_departements' } do
    let(:expected_values) {
      APIGeoService.departements.sort_by { |departement| departement[:code] }.map { |departement| "#{departement[:code]} (#{departement[:name]})" }
    }
    subject(:possible_values) { described_class.new(type_de_champ).possible_values }

    it { expect(possible_values).to match(expected_values) }
  end
end
