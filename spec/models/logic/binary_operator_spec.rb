include Logic

describe Logic::BinaryOperator do
  let(:two_greater_than_one) { greater_than(constant(2), constant(1))}

  describe '#type' do
    it { expect(two_greater_than_one.type).to eq(:boolean) }
  end

  describe '#to_s' do
    it { expect(two_greater_than_one.to_s).to eq('(2 > 1)') }
  end

  describe '#==' do
    it { expect(two_greater_than_one).to eq(greater_than(constant(2), constant(1))) }
    it { expect(two_greater_than_one).not_to eq(greater_than(constant(1), constant(2))) }
  end

  describe '#errors' do
    it { expect(greater_than(constant(1), constant(true)).errors).to eq(['les types sont incompatibles : (1 > true)']) }
  end
end

describe Logic::GreaterThan do
  it 'computes' do
    expect(greater_than(constant(1), constant(1)).compute).to be(false)
    expect(greater_than(constant(2), constant(1)).compute).to be(true)
  end
end

describe Logic::GreaterThanEq do
  it 'computes' do
    expect(greater_than_eq(constant(0), constant(1)).compute).to be(false)
    expect(greater_than_eq(constant(1), constant(1)).compute).to be(true)
    expect(greater_than_eq(constant(2), constant(1)).compute).to be(true)
  end
end

describe Logic::LessThan do
  it 'computes' do
    expect(less_than(constant(1), constant(1)).compute).to be(false)
    expect(less_than(constant(1), constant(2)).compute).to be(true)
  end
end

describe Logic::LessThanEq do
  it 'computes' do
    expect(less_than_eq(constant(0), constant(1)).compute).to be(true)
    expect(less_than_eq(constant(1), constant(1)).compute).to be(true)
    expect(less_than_eq(constant(2), constant(1)).compute).to be(false)
  end
end
