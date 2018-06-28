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

  describe '#for_display' do
    let(:champ) { described_class.new(primary_value: primary_value, secondary_value: secondary_value) }
    let(:primary_value) { nil }
    let(:secondary_value) { nil }

    subject { champ.for_display }

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
end
