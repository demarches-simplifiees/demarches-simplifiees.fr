# frozen_string_literal: true

describe TypeDeChamp do
  describe '#private?' do
    let(:type_de_champ) { build(:type_de_champ, :private) }

    it do
      expect(type_de_champ.private?).to be_truthy
      expect(type_de_champ.public?).to be_falsey
    end
  end
end
