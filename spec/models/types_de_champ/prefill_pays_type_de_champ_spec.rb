
RSpec.describe TypesDeChamp::PrefillPaysTypeDeChamp, type: :model do
  let(:procedure) { create(:procedure) }
  let(:type_de_champ) { build(:type_de_champ_pays, procedure: procedure) }

  describe '#possible_values' do
    let(:expected_values) { "Un <a href=\"https://en.wikipedia.org/wiki/ISO_3166-2\" target=\"_blank\">code pays ISO 3166-2</a><br><a title=\"Toutes les valeurs possibles — Nouvel onglet\" target=\"_blank\" rel=\"noopener noreferrer\" href=\"/procedures/#{procedure.path}/prefill_type_de_champs/#{type_de_champ.id}\">Voir toutes les valeurs possibles</a>" }
    subject(:possible_values) { described_class.new(type_de_champ).possible_values }

    before { type_de_champ.reload }

    it {
      expect(possible_values).to match(expected_values)
    }
  end

  describe '#example_value' do
    subject(:example_value) { described_class.new(type_de_champ).example_value }

    it { expect(example_value).to eq(APIGeoService.countries.sort_by { |country| country[:code] }.first[:code]) }
  end
end
