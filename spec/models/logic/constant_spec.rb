# frozen_string_literal: true

describe Logic::Constant do
  include Logic

  describe '#compute' do
    it { expect(constant(1).compute).to eq(1) }
  end

  describe '#type' do
    it { expect(constant(1).type).to eq(:number) }
    it { expect(constant(1.0).type).to eq(:number) }
    it { expect(constant('a').type).to eq(:string) }
    it { expect(constant(true).type).to eq(:boolean) }
    it { expect(constant(false).type).to eq(:boolean) }
  end

  describe '#errors' do
    it { expect(constant(1).errors).to eq([]) }
  end

  describe '#==' do
    it { expect(constant(1)).to eq(constant(1)) }
    it { expect(constant(1)).not_to eq(constant('a')) }
  end

  describe '#sources' do
    it { expect(constant(1).sources).to eq([]) }
  end
end
