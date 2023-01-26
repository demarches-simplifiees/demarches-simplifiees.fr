describe Logic::Constant do
  include Logic

  describe '#type' do
    it { expect(empty.type).to eq(:empty) }
  end

  describe '#errors' do
    it { expect(empty.errors).to eq(['empty']) }
  end

  describe '#==' do
    it { expect(empty).to eq(empty) }
    it { expect(empty).not_to eq(constant(true)) }
  end

  describe '#to_s' do
    it { expect(empty.to_s).to eq('un membre vide') }
  end

  describe '#sources' do
    it { expect(empty.sources).to eq([]) }
  end
end
