describe Logic::NotEq do
  include Logic

  describe '#compute' do
    it { expect(ds_not_eq(constant(1), constant(1)).compute).to be(false) }
    it { expect(ds_not_eq(constant(1), constant(2)).compute).to be(true) }
  end

  describe '#errors' do
    it { expect(ds_not_eq(constant(true), constant(true)).errors).to be_empty }
    it do
      expected = {
        operator_name: "Logic::NotEq",
        right: constant(1),
        stable_id: nil,
        type: :incompatible
      }
      expect(ds_not_eq(constant(true), constant(1)).errors).to eq([expected])
    end

    it do
      multiple_drop_down = create(:type_de_champ_multiple_drop_down_list)
      first_option = multiple_drop_down.drop_down_list_enabled_non_empty_options.first

      expected = {
        operator_name: "Logic::NotEq",
        stable_id: multiple_drop_down.stable_id,
        type: :required_include
      }

      expect(ds_not_eq(champ_value(multiple_drop_down.stable_id), constant(first_option)).errors([multiple_drop_down])).to eq([expected])
    end
  end

  describe '#==' do
    it { expect(ds_not_eq(constant(true), constant(false))).to eq(ds_not_eq(constant(false), constant(true))) }
  end
end
