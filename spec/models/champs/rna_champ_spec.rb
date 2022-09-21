describe Champs::RNAChamp do
  describe '#valid?' do
    it do
      expect(build(:champ_rna, value: nil)).to be_valid
      expect(build(:champ_rna, value: "2736251627")).to_not be_valid
      expect(build(:champ_rna, value: "A172736283")).to_not be_valid
      expect(build(:champ_rna, value: "W1827362718")).to_not be_valid
      expect(build(:champ_rna, value: "W182736273")).to be_valid
    end
  end
end
