describe Logic::Eq do
  include Logic

  describe '#compute' do
    it { expect(ds_eq(constant(1), constant(1)).compute).to be(true) }
    it { expect(ds_eq(constant(1), constant(2)).compute).to be(false) }
  end

  describe '#errors' do
    it { expect(ds_eq(constant(true), constant(true)).errors).to be_empty }
    it do
      expected = {
        operator_name: "Logic::Eq",
        right: constant(1),
        stable_id: nil,
        type: :incompatible
      }
      expect(ds_eq(constant(true), constant(1)).errors).to eq([expected])
    end
  end

  describe '#==' do
    it { expect(ds_eq(constant(true), constant(false))).to eq(ds_eq(constant(false), constant(true))) }
  end
end
