describe Logic::EmptyOperator do
  include Logic

  describe '#compute' do
    it { expect(empty_operator(empty, empty).compute).to be true }
  end

  describe '#to_query' do
    let(:stable_id) { 2 }
    it { expect(empty_operator(champ_value(stable_id), empty).to_query([]).to_sql).to eq(Champ.where(stable_id:).where(Champ.arel_table[:value].eq(nil)).to_sql) }
  end
end
