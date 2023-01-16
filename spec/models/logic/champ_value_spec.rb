describe Logic::ChampValue do
  include Logic

  subject { champ_value(champ.stable_id).compute([champ]) }

  context 'yes_no tdc' do
    let(:value) { 'true' }
    let(:champ) { create(:champ_yes_no, value: value) }

    it { expect(champ_value(champ.stable_id).type([champ.type_de_champ])).to eq(:boolean) }

    context 'with true value' do
      it { is_expected.to be(true) }
    end

    context 'with false value' do
      let(:value) { 'false' }

      it { is_expected.to be(false) }
    end

    context 'with a value not visible' do
      before do
        expect(champ).to receive(:visible?).and_return(false)
      end

      it { is_expected.to be nil }
    end
  end

  context 'integer tdc' do
    let(:champ) { create(:champ_integer_number, value: '42') }

    it { expect(champ_value(champ.stable_id).type([champ.type_de_champ])).to eq(:number) }
    it { is_expected.to eq(42) }

    context 'with a blank value' do
      let(:champ) { create(:champ_integer_number, value: '') }

      it { is_expected.to be nil }
    end
  end

  context 'decimal tdc' do
    let(:champ) { create(:champ_decimal_number, value: '42.01') }

    it { expect(champ_value(champ.stable_id).type([champ.type_de_champ])).to eq(:number) }
    it { is_expected.to eq(42.01) }
  end

  context 'dropdown tdc' do
    let(:champ) { create(:champ_drop_down_list, value: 'val1') }

    it { expect(champ_value(champ.stable_id).type([champ.type_de_champ])).to eq(:enum) }
    it { is_expected.to eq('val1') }
    it { expect(champ_value(champ.stable_id).options([champ.type_de_champ])).to match_array([["val1", "val1"], ["val2", "val2"], ["val3", "val3"]]) }

    context 'with other enabled' do
      let(:champ) { create(:champ_drop_down_list, value: 'val1', other: true) }

      it { is_expected.to eq('val1') }
      it { expect(champ_value(champ.stable_id).options([champ.type_de_champ])).to match_array([["val1", "val1"], ["val2", "val2"], ["val3", "val3"], ["Autre", "__other__"]]) }
    end

    context 'with other filled' do
      let(:champ) { create(:champ_drop_down_list, value: 'other value', other: true) }

      it { is_expected.to eq(Champs::DropDownListChamp::OTHER) }
    end
  end

  context 'checkbox tdc' do
    let(:champ) { create(:champ_checkbox, value: 'true') }

    it { expect(champ_value(champ.stable_id).type([champ.type_de_champ])).to eq(:boolean) }
    it { is_expected.to eq(true) }
  end

  describe 'errors' do
    let(:champ) { create(:champ) }

    it { expect(champ_value(champ.stable_id).errors([champ.type_de_champ])).to be_empty }
    it { expect(champ_value(champ.stable_id).errors([])).to eq([{ type: :not_available }]) }
  end

  context 'with multiple revision' do
    let(:options) { ['revision_1'] }
    let(:procedure) do
      create(:procedure, :published, :for_individual, types_de_champ_public: [{ type: :drop_down_list, libelle: 'dropdown', options: options }])
    end
    let(:drop_down_r1) { procedure.published_revision.types_de_champ_public.first }
    let(:stable_id) { drop_down_r1.stable_id }

    it { expect(champ_value(stable_id).options([drop_down_r1])).to match_array([["revision_1", "revision_1"]]) }

    context 'with a new revision' do
      let(:drop_down_r2) { procedure.draft_revision.types_de_champ_public.first }

      before do
        tdc = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
        tdc.drop_down_options = ['revision_2']
        tdc.save!
      end

      it do
        expect(champ_value(stable_id).options([drop_down_r2])).to match_array([["revision_2", "revision_2"]])
      end
    end
  end
end
