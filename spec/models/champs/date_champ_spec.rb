describe Champs::DateChamp do
  let(:date_champ) { build(:champ_date) }

  describe '#format_before_save' do
    it 'preserves nil' do
      champ = champ_with_value(nil)
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

    it 'preserves if ISO8601' do
      champ = champ_with_value("2023-12-21")
      champ.save
      expect(champ.reload.value).to eq("2023-12-21")
    end
  end

  def champ_with_value(number)
    date_champ.tap { |c| c.value = number }
  end
end
