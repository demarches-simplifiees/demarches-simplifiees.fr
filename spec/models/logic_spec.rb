describe Logic do
  include Logic

  it 'serializes deserializes' do
    expect(Logic.from_h(constant(1).to_h)).to eq(constant(1))
    expect(Logic.from_json(constant(1).to_json)).to eq(constant(1))

    expect(Logic.from_h(empty.to_h)).to eq(empty)

    expect(Logic.from_h(champ_value(1).to_h)).to eq(champ_value(1))

    expect(Logic.from_h(greater_than(constant(1), constant(2)).to_h)).to eq(greater_than(constant(1), constant(2)))

    expect(Logic.from_h(ds_and([constant(true), constant(true), constant(false)]).to_h))
      .to eq(ds_and([constant(true), constant(true), constant(false)]))
  end

  it 'saves its id' do
    [
      constant(1),
      empty,
      champ_value(1),
      ds_eq(empty, empty),
      ds_and([constant(true), constant(true)])
    ].each do |term|
      expect(Logic.from_h(term.to_h).id).to eq(term.id)
    end
  end

  describe '.ensure_compatibility_from_left' do
    subject { Logic.ensure_compatibility_from_left(condition) }

    context 'when it s fine' do
      let(:condition) { greater_than(constant(1), constant(1)) }

      it { is_expected.to eq(condition) }
    end

    context 'when empty equal true' do
      let(:condition) { ds_eq(empty, constant(true)) }

      it { is_expected.to eq(empty_operator(empty, empty)) }
    end

    context 'when true greater_than 1' do
      let(:condition) { greater_than(constant(true), constant(0)) }

      it { is_expected.to eq(ds_eq(constant(true), constant(true))) }
    end

    context 'when number empty operator true' do
      let(:condition) { empty_operator(constant(1), constant(true)) }

      it { is_expected.to eq(ds_eq(constant(1), constant(0))) }
    end

    context 'when dropdown empty operator true' do
      let(:drop_down) { create(:type_de_champ_drop_down_list) }
      let(:first_option) { drop_down.drop_down_list_enabled_non_empty_options.first }
      let(:condition) { empty_operator(champ_value(drop_down), constant(true)) }

      it { is_expected.to eq(ds_eq(champ_value(drop_down), constant(first_option))) }
    end
  end

  describe '.compatible_type?' do
    it { expect(Logic.compatible_type?(constant(true), constant(true))).to be true }
    it { expect(Logic.compatible_type?(constant(1), constant(true))).to be false }

    context 'with a dropdown' do
      let(:drop_down) { create(:type_de_champ_drop_down_list) }
      let(:first_option) { drop_down.drop_down_list_enabled_non_empty_options.first }

      it do
        expect(Logic.compatible_type?(champ_value(drop_down.stable_id), constant(first_option))).to be true
        expect(Logic.compatible_type?(champ_value(drop_down.stable_id), constant('a'))).to be false
      end
    end
  end

  describe 'priority' do
    # (false && true) || true = true
    it { expect(ds_or([ds_and([constant(false), constant(true)]), constant(true)]).compute).to be true }

    # false && (true || true) = false
    it { expect(ds_and([constant(false), ds_or([constant(true), constant(true)])]).compute).to be false }
  end

  describe '.add_empty_condition_to' do
    it { expect(Logic.add_empty_condition_to(nil)).to eq(empty_operator(empty, empty)) }
    it { expect(Logic.add_empty_condition_to(constant(true))).to eq(ds_and([constant(true), empty_operator(empty, empty)])) }
    it { expect(Logic.add_empty_condition_to(ds_or([constant(true)]))).to eq(ds_or([constant(true), empty_operator(empty, empty)])) }
  end
end
