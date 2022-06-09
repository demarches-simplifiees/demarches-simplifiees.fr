describe Logic do
  include Logic

  it 'serializes deserializes' do
    expect(Logic.from_h(constant(1).to_h)).to eq(constant(1))
    expect(Logic.from_json(constant(1).to_json)).to eq(constant(1))

    expect(Logic.from_h(empty.to_h)).to eq(empty)

    expect(Logic.from_h(greater_than(constant(1), constant(2)).to_h)).to eq(greater_than(constant(1), constant(2)))

    expect(Logic.from_h(ds_and([constant(true), constant(true), constant(false)]).to_h))
      .to eq(ds_and([constant(true), constant(true), constant(false)]))
  end

  describe '.compatible_type?' do
    it { expect(Logic.compatible_type?(constant(true), constant(true))).to be true }
    it { expect(Logic.compatible_type?(constant(1), constant(true))).to be false }
  end

  describe 'priority' do
    # (false && true) || true = true
    it { expect(ds_or([ds_and([constant(false), constant(true)]), constant(true)]).compute).to be true }

    # false && (true || true) = false
    it { expect(ds_and([constant(false), ds_or([constant(true), constant(true)])]).compute).to be false }
  end
end
