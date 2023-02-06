# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillEpciTypeDeChamp do
  let(:type_de_champ) { build(:type_de_champ_epci) }

  describe 'ancestors' do
    subject { described_class.new(type_de_champ) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillEpciTypeDeChamp) }
  end
  # TODO: SEB describe '#possible_values'
  # TODO: SEB describe '#example_value'

  describe '#transform_value_to_assignable_attributes' do
    subject(:transform_value_to_assignable_attributes) { described_class.build(type_de_champ).transform_value_to_assignable_attributes(value) }

    context 'when the value is nil' do
      let(:value) { nil }
      it { is_expected.to match({ code_departement: nil, value: nil }) }
    end

    context 'when the value is empty' do
      let(:value) { '' }
      it { is_expected.to match({ code_departement: nil, value: nil }) }
    end

    context 'when the value is a string' do
      let(:value) { 'hello' }
      it { is_expected.to match({ code_departement: nil, value: nil }) }
    end

    context 'when the value is an array of one element' do
      let(:value) { ['01'] }
      it { is_expected.to match({ code_departement: '01', value: nil }) }
    end

    context 'when the value is an array of two elements' do
      let(:value) { ['01', '200042935'] }
      it { is_expected.to match({ code_departement: '01', value: '200042935' }) }
    end

    context 'when the value is an array of three or more elements' do
      let(:value) { ['01', '200042935', 'hello'] }
      it { is_expected.to match({ code_departement: '01', value: '200042935' }) }
    end
  end
end
