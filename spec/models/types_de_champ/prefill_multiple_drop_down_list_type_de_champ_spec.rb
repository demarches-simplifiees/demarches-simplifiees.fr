# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillMultipleDropDownListTypeDeChamp do
  let(:procedure) { create(:procedure) }

  describe 'ancestors' do
    subject { described_class.new(build(:type_de_champ_multiple_drop_down_list, procedure: procedure), procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillDropDownListTypeDeChamp) }
  end

  describe '#example_value' do
    let(:type_de_champ) { build(:type_de_champ_multiple_drop_down_list, drop_down_list_value: drop_down_list_value, procedure: procedure) }
    subject(:example_value) { described_class.new(type_de_champ, procedure.active_revision).example_value }

    context 'when the multiple drop down list has no option' do
      let(:drop_down_list_value) { "" }

      it { expect(example_value).to eq(nil) }
    end

    context 'when the multiple drop down list only has one option' do
      let(:drop_down_list_value) { "value" }

      it { expect(example_value).to eq("value") }
    end

    context 'when the multiple drop down list has two options or more' do
      let(:drop_down_list_value) {  "value1\r\nvalue2\r\nvalue3" }

      it { expect(example_value).to eq(["value1", "value2"]) }
    end
  end
end
