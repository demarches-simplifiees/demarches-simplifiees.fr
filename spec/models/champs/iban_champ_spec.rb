describe Champs::IbanChamp do
  describe '#valid?' do
    it do
      expect(build(:champ_iban, value: nil).valid?(:champs_public_value)).to be_truthy
      expect(build(:champ_iban, value: "FR35 KDSQFDJQSMFDQMFDQ").valid?(:champs_public_value)).to be_falsey
      expect(build(:champ_iban, value: "FR7630006000011234567890189").valid?(:champs_public_value)).to be_truthy
      expect(build(:champ_iban, value: "FR76 3000 6000 0112 3456 7890 189").valid?(:champs_public_value)).to be_truthy
      expect(build(:champ_iban, value: "FR76 3000 6000 0112 3456 7890 189DSF").valid?(:champs_public_value)).to be_falsey
      expect(build(:champ_iban, value: "FR76	3000	6000	0112	3456	7890	189").valid?(:champs_public_value)).to be_truthy
    end

    it 'format value after validation' do
      champ = build(:champ_iban, value: "FR76	3000	6000	0112	3456	7890	189")
      champ.valid?(:champs_public_value)
      expect(champ.value).to eq("FR76 3000 6000 0112 3456 7890 189")
    end
  end
end
