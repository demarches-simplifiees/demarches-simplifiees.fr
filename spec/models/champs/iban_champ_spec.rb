
describe Champs::IbanChamp do
  describe '#valid?' do
    it do
      expect(build(:champ_iban, value: nil)).to be_valid
      expect(build(:champ_iban, value: "FR35 KDSQFDJQSMFDQMFDQ")).to_not be_valid
      expect(build(:champ_iban, value: "FR7630006000011234567890189")).to be_valid
      expect(build(:champ_iban, value: "FR76 3000 6000 0112 3456 7890 189")).to be_valid
      expect(build(:champ_iban, value: "FR76 3000 6000 0112 3456 7890 189DSF")).to_not be_valid
    end
  end
end
