describe Champs::DateChamp do
  let(:date_champ) { build(:champ_date) }

  describe '#convert_to_iso8601' do
    it 'preserves nil' do
      champ = champ_with_value(nil)
      champ.save
      expect(champ.reload.value).to be_nil
    end

    it 'converts to nil if empty string' do
      champ = champ_with_value("")
      champ.save
      expect(champ.reload.value).to be_nil
    end

    it 'converts to nil if not ISO8601' do
      champ = champ_with_value("12-21-2023")
      champ.save
      expect(champ.reload.value).to be_nil
    end

    it 'converts to nil if not date' do
      champ = champ_with_value("value")
      champ.save
      expect(champ.reload.value).to be_nil
    end

    it "converts %d/%m/%Y format to ISO" do
      champ = champ_with_value("31/12/2017")
      champ.save
      expect(champ.reload.value).to eq("2017-12-31")
    end

    it 'preserves if ISO8601' do
      champ = champ_with_value("2023-12-21")
      champ.save
      expect(champ.reload.value).to eq("2023-12-21")
    end
  end

  describe 'validate :iso_8601' do
    it 'works' do
      date_champ.value = '2023-27-02'
      date_champ.send(:iso_8601)
      expect(date_champ.valid?).to eq(false)
      expect(date_champ.to_s).not_to raise_error
    end
  end
  def champ_with_value(number)
    date_champ.tap { |c| c.value = number }
  end
end
