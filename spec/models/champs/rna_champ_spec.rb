describe Champs::RNAChamp do
  let(:champ) { create(:champ_rna, value: "W182736273") }

  describe '#valid?' do
    it do
      expect(build(:champ_rna, value: nil)).to be_valid
      expect(build(:champ_rna, value: "2736251627")).to_not be_valid
      expect(build(:champ_rna, value: "A172736283")).to_not be_valid
      expect(build(:champ_rna, value: "W1827362718")).to_not be_valid
      expect(build(:champ_rna, value: "W182736273")).to be_valid
    end
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

  describe 'external_id' do
    context 'when all data required for an external fetch are given' do
      it { expect(champ.external_id).to eq("W182736273") }
    end
  end
end
