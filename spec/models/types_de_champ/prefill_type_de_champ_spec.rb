# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillTypeDeChamp, type: :model do
  describe '.build' do
    subject(:built) { described_class.build(type_de_champ) }

    context 'when the type de champ is a drop_down_list' do
      let(:type_de_champ) { build(:type_de_champ_drop_down_list) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillDropDownListTypeDeChamp) }
    end

    context 'when the type de champ is a pays' do
      let(:type_de_champ) { build(:type_de_champ_pays) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillPaysTypeDeChamp) }
    end

    context 'when any other type de champ' do
      let(:type_de_champ) { build(:type_de_champ_date) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
    end
  end

  describe '.wrap' do
    subject(:wrapped) { described_class.wrap([build(:type_de_champ_drop_down_list), build(:type_de_champ_email)]) }

    it 'wraps the collection' do
      expect(wrapped.first).to be_kind_of(TypesDeChamp::PrefillDropDownListTypeDeChamp)
      expect(wrapped.last).to be_kind_of(TypesDeChamp::PrefillTypeDeChamp)
    end
  end

  describe '#possible_values' do
    subject(:possible_values) { described_class.build(type_de_champ).possible_values }

    context 'when the type de champ is not prefillable' do
      let(:type_de_champ) { build(:type_de_champ_mesri) }

      it { expect(possible_values).to be_empty }
    end

    context 'when the type de champ is prefillable' do
      let(:type_de_champ) { build(:type_de_champ_email) }

      it { expect(possible_values).to match([]) }
    end
  end

  describe '#example_value' do
    subject(:example_value) { described_class.build(type_de_champ).example_value }

    context 'when the type de champ is not prefillable' do
      let(:type_de_champ) { build(:type_de_champ_mesri) }

      it { expect(example_value).to be_nil }
    end

    context 'when the type de champ is prefillable' do
      let(:type_de_champ) { build(:type_de_champ_email) }

      it { expect(example_value).to eq(I18n.t("views.prefill_descriptions.edit.examples.#{type_de_champ.type_champ}")) }
    end
  end

  describe '#too_many_possible_values?' do
    let(:type_de_champ) { build(:type_de_champ_drop_down_list) }
    subject(:too_many_possible_values) { described_class.build(type_de_champ).too_many_possible_values? }

    context 'when there are too many possible values' do
      before { type_de_champ.drop_down_options = (1..described_class::POSSIBLE_VALUES_THRESHOLD + 1).map(&:to_s) }

      it { expect(too_many_possible_values).to eq(true) }
    end

    context 'when there are not too many possible values' do
      before { type_de_champ.drop_down_options = (1..described_class::POSSIBLE_VALUES_THRESHOLD).map(&:to_s) }

      it { expect(too_many_possible_values).to eq(false) }
    end
  end

  describe '#possible_values_sample' do
    let(:drop_down_options) { (1..described_class::POSSIBLE_VALUES_THRESHOLD + 1).map(&:to_s) }
    let(:type_de_champ) { build(:type_de_champ_drop_down_list, drop_down_options: drop_down_options) }
    subject(:possible_values_sample) { described_class.build(type_de_champ).possible_values_sample }

    it { expect(possible_values_sample).to match(drop_down_options.first(described_class::POSSIBLE_VALUES_THRESHOLD)) }
  end
end
