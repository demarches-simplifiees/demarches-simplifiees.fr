# frozen_string_literal: true

describe Champs::DatetimeChamp do
  let(:datetime_champ) { described_class.new }

  describe '#convert_to_iso8601' do
    it 'preserves nil' do
      champ = champ_with_value(nil)
      champ.run_callbacks(:validation)
      expect(champ.value).to be_nil
    end

    it 'converts to nil if empty string' do
      champ = champ_with_value("")
      champ.run_callbacks(:validation)
      expect(champ.value).to be_nil
    end

    it 'converts to nil if not ISO8601' do
      champ = champ_with_value("12-21-2023 03:20")
      champ.run_callbacks(:validation)
      expect(champ.value).to be_nil
    end

    it 'converts to nil if not datetime' do
      champ = champ_with_value("value")
      champ.run_callbacks(:validation)
      expect(champ.value).to be_nil
    end

    it 'preserves if ISO8601' do
      champ = champ_with_value("2023-12-21T03:20")
      champ.run_callbacks(:validation)
      expect(champ.value).to eq(Time.zone.parse("2023-12-21T03:20:00").iso8601)
    end

    it 'converts to ISO8601 if form format' do
      champ = champ_with_value("{3=>21, 2=>12, 1=>2023, 4=>3, 5=>20}")
      champ.run_callbacks(:validation)
      expect(champ.value).to eq(Time.zone.parse("2023-12-21T03:20:00").iso8601)
    end

    it 'converts to ISO8601 if old browser form format' do
      champ = champ_with_value("21/12/2023 03:20")
      champ.run_callbacks(:validation)
      expect(champ.value).to eq(Time.zone.parse("2023-12-21T03:20:00").iso8601)
    end
  end

  def champ_with_value(number)
    datetime_champ.tap { |c| c.value = number }
  end
end
