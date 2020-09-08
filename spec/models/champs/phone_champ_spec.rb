describe Champs::PhoneChamp do
  describe '#valid?' do
    it do
      expect(build(:champ_phone, value: nil)).to be_valid
      expect(build(:champ_phone, value: "0123456789 0123456789")).to_not be_valid
      expect(build(:champ_phone, value: "01.23.45.67.89 01.23.45.67.89")).to_not be_valid
      expect(build(:champ_phone, value: "3646")).to be_valid
      expect(build(:champ_phone, value: "0123456789")).to be_valid
      expect(build(:champ_phone, value: "01.23.45.67.89")).to be_valid
      expect(build(:champ_phone, value: "0123 45.67.89")).to be_valid
      expect(build(:champ_phone, value: "0033 123-456-789")).to be_valid
      expect(build(:champ_phone, value: "0033 123-456-789")).to be_valid
      expect(build(:champ_phone, value: "0033(0)123456789")).to be_valid
      expect(build(:champ_phone, value: "+33-1.23.45.67.89")).to be_valid
      expect(build(:champ_phone, value: "+33 - 123 456 789")).to be_valid
      expect(build(:champ_phone, value: "+33(0) 123 456 789")).to be_valid
      expect(build(:champ_phone, value: "+33 (0)123 45 67 89")).to be_valid
      expect(build(:champ_phone, value: "+33 (0)1 2345-6789")).to be_valid
      expect(build(:champ_phone, value: "+33(0) - 123456789")).to be_valid
      expect(build(:champ_phone, value: "+1(0) - 123456789")).to be_valid
      expect(build(:champ_phone, value: "+49 2109 87654321")).to be_valid
      expect(build(:champ_phone, value: "012345678")).to be_valid
      # polynesian numbers should not return errors in any way
      ## landline numbers start with 40 or 45
      expect(build(:champ_phone, value: "45187272")).to be_valid
      expect(build(:champ_phone, value: "40 473 500")).to be_valid
      expect(build(:champ_phone, value: "40473500")).to be_valid
      expect(build(:champ_phone, value: "45473500")).to be_valid
      ## +689 is the international indicator
      expect(build(:champ_phone, value: "+689 45473500")).to be_valid
      expect(build(:champ_phone, value: "0145473500")).to be_valid
      ## polynesian mobile numbers start with 87, 88, 89
      expect(build(:champ_phone, value: "87473500")).to be_valid
      expect(build(:champ_phone, value: "88473500")).to be_valid
      expect(build(:champ_phone, value: "89473500")).to be_valid
    end
  end
end
