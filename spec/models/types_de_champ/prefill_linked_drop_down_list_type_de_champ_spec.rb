# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillLinkedDropDownListTypeDeChamp do
  let(:drop_down_list_value) { "--first--\nvalue1\nvalue2" }
  let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list, drop_down_list_value:) }

  describe 'ancestors' do
    subject { described_class.new(type_de_champ) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values' do
    let(:expected_possible_values) { drop_down_list_value.split("\n") }
    subject(:possible_values) { described_class.new(type_de_champ).possible_values }

    it { expect(possible_values).to match(expected_possible_values) }
  end

  describe '#example_value' do
    subject(:example_value) { described_class.new(type_de_champ).example_value }

    it { expect(example_value).to eq(['--first--', 'value1']) }

    context 'when there is no options' do
      let(:drop_down_list_value) { nil }

      it { expect(example_value).to eq(nil) }
    end

    context 'when there is only one option' do
      let(:drop_down_list_value) { "the world is a vampire" }

      it { expect(example_value).to eq(drop_down_list_value) }
    end
  end
end
