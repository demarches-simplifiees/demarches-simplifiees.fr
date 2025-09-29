# frozen_string_literal: true

describe Logic::Constant do
  include Logic

  describe '#compute' do
    it { expect(constant(1).compute).to eq(1) }
  end

  describe '#type' do
    it do
      expect(constant(1).type).to eq(:number)
      expect(constant(1.0).type).to eq(:number)
      expect(constant('a').type).to eq(:string)
      expect(constant(true).type).to eq(:boolean)
      expect(constant(false).type).to eq(:boolean)
    end
  end

  describe '#errors' do
    it { expect(constant(1).errors).to eq([]) }
  end

  describe '#==' do
    it do
      expect(constant(1)).to eq(constant(1))
      expect(constant(1)).not_to eq(constant('a'))
    end
  end

  describe '#sources' do
    it { expect(constant(1).sources).to eq([]) }
  end
end
