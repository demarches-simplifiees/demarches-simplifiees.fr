describe Logic::And do
  include Logic

  describe '#compute' do
    it { expect(and_from([true, true, true]).compute).to be true }
    it { expect(and_from([true, true, false]).compute).to be false }
  end

  describe '#to_s' do
    it do
      expect(and_from([true, false, true]).to_s([])).to eq "(Oui && Non && Oui)"
    end
  end

  def and_from(boolean_to_constants)
    ds_and(boolean_to_constants.map { |b| constant(b) })
  end

  describe '#to_query' do
    let(:or_condition) { ds_and([condition_1, condition_2]) }
    let(:condition_1) { ds_eq(champ_value(1), constant(1)) }
    let(:condition_2) { ds_eq(champ_value(2), constant(2)) }

    it do
      expect(or_condition.to_query([]).to_sql).to eq(
        Champ.where(stable_id: 1).where(value: 1).and(Champ.where(stable_id: 2).where(value: 2)).to_sql
      )
    end
  end
end
