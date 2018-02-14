require 'spec_helper'

describe TypeDeChamp do
  describe '#private?' do
    let(:type_de_champ) { build(:type_de_champ, :private) }

    it { expect(type_de_champ.private?).to be_truthy }
    it { expect(type_de_champ.public?).to be_falsey }
  end
end
