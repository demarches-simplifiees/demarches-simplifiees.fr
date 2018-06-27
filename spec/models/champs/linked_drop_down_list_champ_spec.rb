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
end
