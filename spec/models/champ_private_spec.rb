require 'spec_helper'

describe Champ do
  describe '#private?' do
    let(:type_de_champ) { build(:type_de_champ, :private) }
    let(:champ) { type_de_champ.champ.build }

    it { expect(champ.private?).to be_truthy }
    it { expect(champ.public?).to be_falsey }
  end
end
