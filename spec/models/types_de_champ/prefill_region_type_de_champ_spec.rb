# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillRegionTypeDeChamp, type: :model do
  let(:type_de_champ) { build(:type_de_champ_regions) }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe '#possible_values', vcr: { cassette_name: 'api_geo_regions' } do
    let(:expected_values) { APIGeoService.regions.sort_by { |region| region[:code] }.map { |region| "#{region[:code]} (#{region[:name]})" } }
    subject(:possible_values) { described_class.new(type_de_champ).possible_values }

    it { expect(possible_values).to match(expected_values) }
  end

  describe '#example_value', vcr: { cassette_name: 'api_geo_regions' } do
    subject(:example_value) { described_class.new(type_de_champ).example_value }

    it { expect(example_value).to eq(APIGeoService.regions.sort_by { |region| region[:code] }.first[:code]) }
  end
end
