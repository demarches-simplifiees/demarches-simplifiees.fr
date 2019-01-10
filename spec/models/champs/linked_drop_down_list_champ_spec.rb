require 'spec_helper'

describe Champs::LinkedDropDownListChamp do
  describe '#unpack_value' do
    let(:champ) { described_class.new(value: '["tata", "tutu"]') }

    it { expect(champ.primary_value).to eq('tata') }
    it { expect(champ.secondary_value).to eq('tutu') }
  end

  describe '#pack_value' do
    let(:champ) { described_class.new(primary_value: 'tata', secondary_value: 'tutu') }

    before { champ.save }

    it { expect(champ.value).to eq('["tata","tutu"]') }
  end

  describe '#to_s' do
    let(:champ) { described_class.new(primary_value: primary_value, secondary_value: secondary_value) }
    let(:primary_value) { nil }
    let(:secondary_value) { nil }

    subject { champ.to_s }

    context 'with no value' do
      it { is_expected.to eq('') }
    end

    context 'with primary value' do
      let(:primary_value) { 'primary' }

      it { is_expected.to eq('primary') }
    end

    context 'with secondary value' do
      let(:primary_value) { 'primary' }
      let(:secondary_value) { 'secondary' }

      it { is_expected.to eq('primary / secondary') }
    end
  end

  describe 'for_export' do
    subject { champ.for_export }

    context 'with no value' do
      let(:champ) { described_class.new }

      it { is_expected.to be_nil }
    end

    context 'with primary value' do
      let(:champ) { described_class.new(primary_value: 'primary') }

      it { is_expected.to eq('primary;') }
    end

    context 'with secondary value' do
      let(:champ) { described_class.new(primary_value: 'primary', secondary_value: 'secondary') }

      it { is_expected.to eq('primary;secondary') }
    end
  end

  describe '#mandatory_and_blank' do
    let(:drop_down_list) { build(:drop_down_list, value: "--Primary--\nSecondary") }

    subject { described_class.new(type_de_champ: type_de_champ) }

    context 'when the champ is not mandatory' do
      let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list, drop_down_list: drop_down_list) }

      it 'blank is fine' do
        is_expected.not_to be_mandatory_and_blank
      end
    end

    context 'when the champ is mandatory' do
      let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list, mandatory: true, drop_down_list: drop_down_list) }

      context 'when there is no value' do
        it { is_expected.to be_mandatory_and_blank }
      end

      context 'when there is a primary value' do
        before { subject.primary_value = 'Primary' }

        context 'when there is no secondary value' do
          it { is_expected.to be_mandatory_and_blank }
        end

        context 'when there is a secondary value' do
          before { subject.secondary_value = 'Primary' }

          it { is_expected.not_to be_mandatory_and_blank }
        end
      end
    end
  end
end
