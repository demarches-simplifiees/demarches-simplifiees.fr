# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillDropDownListTypeDeChamp do
  let(:type_de_champ) { build(:type_de_champ_drop_down_list) }

  describe '#possible_values' do
    subject(:possible_values) { described_class.new(type_de_champ).possible_values }

    it { expect(possible_values).to match(type_de_champ.drop_down_list_enabled_non_empty_options) }
  end

  describe '#example_value' do
    subject(:example_value) { described_class.new(type_de_champ).example_value }

    it { expect(example_value).to eq(type_de_champ.drop_down_list_enabled_non_empty_options.first) }
  end
end
