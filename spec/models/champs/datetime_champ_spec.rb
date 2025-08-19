# frozen_string_literal: true

describe Champs::DatetimeChamp do
  let(:types_de_champ_public) { [{ type: :datetime }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:datetime_champ) { dossier.champs.first }

  describe '#normalizes' do
    it 'preserves nil' do
      champ = champ_with_value(nil)
      expect(champ.value).to be_nil
    end

    it 'converts to nil if empty string' do
      champ = champ_with_value("")
      expect(champ.value).to be_nil
    end

    it 'converts to nil if not ISO8601' do
      champ = champ_with_value("12-21-2023 03:20")
      expect(champ.value).to be_nil
    end

    it 'converts to nil if not datetime' do
      champ = champ_with_value("value")
      expect(champ.value).to be_nil
    end

    it 'preserves if ISO8601' do
      champ = champ_with_value("2023-12-21T03:20")
      expect(champ.value).to eq(Time.zone.parse("2023-12-21T03:20:00").iso8601)
    end

    it 'converts to ISO8601 if form format' do
      champ = champ_with_value("{3=>21, 2=>12, 1=>2023, 4=>3, 5=>20}")
      expect(champ.value).to eq(Time.zone.parse("2023-12-21T03:20:00").iso8601)
    end

    it 'converts to ISO8601 if old browser form format' do
      champ = champ_with_value("21/12/2023 03:20")
      expect(champ.value).to eq(Time.zone.parse("2023-12-21T03:20:00").iso8601)
    end
  end

  describe '#valid?' do
    it 'should not change the value' do
      sql = "UPDATE champs SET value = 'invalid' WHERE id = #{datetime_champ.id}"
      ActiveRecord::Base.connection.execute(sql)
      datetime_champ.reload
      expect(datetime_champ.value).to eq("invalid")

      expect(datetime_champ.valid?).to be_falsey
      error = datetime_champ.errors.first
      expect(error.attribute).to eq(:value)
    end
  end

  context 'when the value is not in the past' do
    subject { datetime_champ.validate(:champs_public_value) }

    context 'all dates are accepted' do
      before { datetime_champ.update(value: DateTime.now.iso8601) }

      it { is_expected.to be_truthy }
    end

    context 'dates not in past are not accepted' do
      let(:now) { DateTime.parse('2023-10-01') }

      before do
        travel_to(now)
        datetime_champ.type_de_champ.update(options: { date_in_past: '1' })
        datetime_champ.update(value:)
      end

      context 'when the value is in the future or today' do
        let(:value) { now.iso8601 }

        it 'is not valid and contains errors' do
          is_expected.to be_falsey
          expect(datetime_champ.errors[:value]).to eq(["doit être une date dans le passé"])
        end
      end

      context 'when the value one day before' do
        let(:value) { (now - 1.day).iso8601 }

        it 'is valid' do
          is_expected.to be_truthy
        end
      end
    end
  end

  context 'when there is a range' do
    let(:champ) { dossier.champs.first.tap { _1.update(value:) } }
    subject { champ.validate(:champs_public_value) }

    before { champ.type_de_champ.update(options: { range_date: '1', start_date: '2017-11-30', end_date: '2017-12-31' }) }
    context 'the value is in the range' do
      let(:value) { "2017-12-15T00:01:00+01:00" }

      it { is_expected.to be_truthy }
    end

    context 'the value is not in the range' do
      let(:value) { "2017-10-15T00:01:00+01:00" }

      it 'is not valid and contains errors' do
        is_expected.to be_falsey
        expect(champ.errors[:value]).to eq(["doit être une date comprise entre le 30 novembre 2017 et le 31 décembre 2017"])
      end
    end

    context 'the value is bigger than max' do
      before { champ.type_de_champ.update(options: { range_date: '1', start_date: '', end_date: '2017-12-31' }) }
      let(:value) { "2018-12-15T00:01:00+01:00" }

      it 'is not valid and contains errors' do
        is_expected.to be_falsey
        expect(champ.errors[:value]).to eq(["doit être une date inférieure ou égale au 31 décembre 2017"])
      end
    end

    context 'the value is smaller than min' do
      before { champ.type_de_champ.update(options: { range_date: '1', start_date: '2017-11-30', end_date: '' }) }
      let(:value) { "2016-12-15T00:01:00+01:00" }

      it 'is not valid and contains errors' do
        is_expected.to be_falsey
        expect(champ.errors[:value]).to eq(["doit être une date supérieure ou égale au 30 novembre 2017"])
      end
    end

    context 'the range is not activated' do
      before { champ.type_de_champ.update(options: { range_date: '0', start_date: '2017-11-30', end_date: '2017-12-31' }) }
      let(:value) { "2017-12-15T00:01:00+01:00" }

      it { is_expected.to be_truthy }
    end

    context 'the range is activated but min and max values are not defined' do
      before { champ.type_de_champ.update(options: { range_date: '0', start_date: '', end_date: '' }) }
      let(:value) { "2017-12-15T00:01:00+01:00" }

      it { is_expected.to be_truthy }
    end
  end

  def champ_with_value(number)
    datetime_champ.tap { |c| c.value = number }
  end
end
