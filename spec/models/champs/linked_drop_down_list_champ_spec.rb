require 'spec_helper'

describe Champs::LinkedDropDownListChamp do
  describe '#unpack_value' do
    let(:champ) { described_class.new(value: '["tata", "tutu"]') }

    it { expect(champ.master_value).to eq('tata') }
    it { expect(champ.slave_value).to eq('tutu') }
  end

  describe '#pack_value' do
    let(:champ) { described_class.new(master_value: 'tata', slave_value: 'tutu') }

    before { champ.save }

    it { expect(champ.value).to eq('["tata","tutu"]') }
  end
end
