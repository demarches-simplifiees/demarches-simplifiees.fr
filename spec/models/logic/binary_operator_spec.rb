describe Logic::BinaryOperator do
  include Logic
  let(:two_greater_than_one) { greater_than(constant(2), constant(1)) }

  describe '#type' do
    it { expect(two_greater_than_one.type).to eq(:boolean) }
  end

  describe '#to_s' do
    it { expect(two_greater_than_one.to_s([])).to eq('(2 > 1)') }
  end

  describe '#==' do
    it { expect(two_greater_than_one).to eq(greater_than(constant(2), constant(1))) }
    it { expect(two_greater_than_one).not_to eq(greater_than(constant(1), constant(2))) }
  end

  describe '#errors' do
    it { expect(greater_than(constant(1), constant(true)).errors).to eq([{ operator_name: "Logic::GreaterThan", type: :required_number }]) }
  end

  describe '#sources' do
    let(:champ) { create(:champ_integer_number, value: nil) }
    let(:champ2) { create(:champ_integer_number, value: nil) }

    it { expect(two_greater_than_one.sources).to eq([]) }
    it { expect(greater_than(champ_value(champ.stable_id), constant(2)).sources).to eq([champ.stable_id]) }
    it { expect(greater_than(constant(2), champ_value(champ.stable_id)).sources).to eq([champ.stable_id]) }
    it { expect(greater_than(champ_value(champ.stable_id), champ_value(champ2.stable_id)).sources).to eq([champ.stable_id, champ2.stable_id]) }
  end
end

describe Logic::GreaterThan do
  include Logic
  let(:champ) { create(:champ_integer_number, value: nil) }

  it 'computes' do
    expect(greater_than(constant(1), constant(1)).compute).to be(false)
    expect(greater_than(constant(2), constant(1)).compute).to be(true)
    expect(greater_than(champ_value(champ.stable_id), constant(2)).compute([champ])).to be(false)
  end
end

describe Logic::GreaterThanEq do
  include Logic
  let(:champ) { create(:champ_integer_number, value: nil) }

  it 'computes' do
    expect(greater_than_eq(constant(0), constant(1)).compute).to be(false)
    expect(greater_than_eq(constant(1), constant(1)).compute).to be(true)
    expect(greater_than_eq(constant(2), constant(1)).compute).to be(true)
  end
end

describe Logic::LessThan do
  include Logic
  it 'computes' do
    expect(less_than(constant(1), constant(1)).compute).to be(false)
    expect(less_than(constant(1), constant(2)).compute).to be(true)
  end
end

describe Logic::LessThanEq do
  include Logic
  it 'computes' do
    expect(less_than_eq(constant(0), constant(1)).compute).to be(true)
    expect(less_than_eq(constant(1), constant(1)).compute).to be(true)
    expect(less_than_eq(constant(2), constant(1)).compute).to be(false)
  end
end
