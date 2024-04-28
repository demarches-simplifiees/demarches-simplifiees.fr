# frozen_string_literal: true

describe Champs::RNAChamp do
  let(:champ) { Champs::RNAChamp.new(value: "W182736273", dossier: build(:dossier)) }
  before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_rna)) }
  def with_value(value)
    champ.tap { _1.value = value }
  end
  describe '#valid?' do
    it { expect(with_value(nil).validate(:champs_public_value)).to be_truthy }
    it { expect(with_value("2736251627").validate(:champs_public_value)).to be_falsey }
    it { expect(with_value("A172736283").validate(:champs_public_value)).to be_falsey }
    it { expect(with_value("W1827362718").validate(:champs_public_value)).to be_falsey }
    it { expect(with_value("W182736273").validate(:champs_public_value)).to be_truthy }
  end

  describe "#export" do
    context "with association title" do
      before do
        champ.update(data: { association_titre: "Super asso" })
      end

      it { expect(champ.for_export).to eq("W182736273 (Super asso)") }
    end

    context "no association title" do
      it { expect(champ.for_export).to eq("W182736273") }
    end
  end
end
