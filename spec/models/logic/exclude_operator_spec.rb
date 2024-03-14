describe Logic::ExcludeOperator do
  include Logic

  let(:champ) { create(:champ_multiple_drop_down_list, value: '["val1", "val2"]') }

  describe '#compute' do
    it { expect(ds_exclude(champ_value(champ.stable_id), constant('val1')).compute([champ])).to be(false) }
    it { expect(ds_exclude(champ_value(champ.stable_id), constant('something else')).compute([champ])).to be(true) }
  end

  describe '#errors' do
    it { expect(ds_exclude(champ_value(champ.stable_id), constant('val1')).errors([champ.type_de_champ])).to be_empty }
    it do
      expected = {
        right: constant('something else'),
        stable_id: champ.stable_id,
        type: :not_included
      }

      expect(ds_exclude(champ_value(champ.stable_id), constant('something else')).errors([champ.type_de_champ])).to eq([expected])
    end

    it { expect(ds_exclude(constant(1), constant('val1')).errors([])).to eq([{ type: :required_list }]) }
  end

  describe '#==' do
    it { expect(ds_include(champ_value(champ.stable_id), constant('val1'))).to eq(ds_include(champ_value(champ.stable_id), constant('val1'))) }
  end
end
