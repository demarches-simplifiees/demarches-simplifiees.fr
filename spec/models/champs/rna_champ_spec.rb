# frozen_string_literal: true

describe Champs::RNAChamp do
  let(:types_de_champ_public) { [{ type: :rna }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first.tap { _1.update(value:) } }
  let(:value) { "W182736273" }

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

      it { expect(champ.type_de_champ.champ_value_for_export(champ)).to eq("W182736273 (Super asso)") }
    end

    context "no association title" do
      it { expect(champ.type_de_champ.champ_value_for_export(champ)).to eq("W182736273") }
    end
  end
end
