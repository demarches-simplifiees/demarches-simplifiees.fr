describe Logic::NAryOperator do
  include Logic

  describe '#errors' do
    it { expect(ds_and([]).errors).to eq(["opérateur 'Et' vide"]) }
    it { expect(ds_and([constant(1), constant('toto')]).errors).to eq(["'Et' ne contient pas que des booléens : 1, toto"]) }
    it { expect(ds_and([double(type: :boolean, errors: ['from double'])]).errors).to eq(["from double"]) }
  end

  describe '#==' do
    it do
      expect(and_from([true, true, false])).to eq(and_from([false, true, true]))
      expect(and_from([true, true, false])).not_to eq(and_from([false, false, true]))

      # perf test
      left = [false, false] + Array.new(10) { true }
      right = [false] + Array.new(11) { true }
      expect(and_from(left)).not_to eq(and_from(right))

      left = (1..10).to_a
      right = (1..10).to_a.reverse
      expect(and_from(left)).to eq(and_from(right))
    end
  end

  describe '#sources' do
    it { expect(and_from([false, true]).sources).to eq([]) }
  end

  def and_from(boolean_to_constants)
    ds_and(boolean_to_constants.map { |b| constant(b) })
  end
end
