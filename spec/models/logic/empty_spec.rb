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
end
