
RSpec.describe TypesDeChamp::PrefillPaysTypeDeChamp, type: :model do
  let(:type_de_champ) { build(:type_de_champ_pays) }

  describe 'ancestors' do
    subject { described_class.build(type_de_champ) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values' do
    let(:expected_values) { APIGeoService.countries.sort_by { |country| country[:code] }.map { |country| "#{country[:code]} (#{country[:name]})" } }
    subject(:possible_values) { described_class.new(type_de_champ).possible_values }

    it { expect(possible_values).to match(expected_values) }
  end
end
