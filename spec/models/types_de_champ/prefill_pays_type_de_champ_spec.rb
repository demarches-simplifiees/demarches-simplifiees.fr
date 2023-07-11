
RSpec.describe TypesDeChamp::PrefillPaysTypeDeChamp, type: :model do
  let(:type_de_champ) { build(:type_de_champ_pays) }

  describe '#possible_values' do
    let(:expected_values) { APIGeoService.countries.sort_by { |country| country[:code] }.map { |country| "#{country[:code]} (#{country[:name]})" } }
    subject(:possible_values) { described_class.new(type_de_champ).possible_values }

    it { expect(possible_values).to match(expected_values) }
  end

  describe '#example_value' do
    subject(:example_value) { described_class.new(type_de_champ).example_value }

    it { expect(example_value).to eq(APIGeoService.countries.sort_by { |country| country[:code] }.first[:code]) }
  end
end
