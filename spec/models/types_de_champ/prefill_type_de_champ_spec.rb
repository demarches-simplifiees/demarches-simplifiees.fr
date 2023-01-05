# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillTypeDeChamp, type: :model do
  describe '.build' do
    subject(:built) { described_class.build(type_de_champ) }

    context 'when the type de champ is a drop_down_list' do
      let(:type_de_champ) { build(:type_de_champ_drop_down_list) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillDropDownListTypeDeChamp) }
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

      it { expect(possible_values).to match([I18n.t("views.prefill_descriptions.edit.possible_values.#{type_de_champ.type_champ}")]) }
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
end
