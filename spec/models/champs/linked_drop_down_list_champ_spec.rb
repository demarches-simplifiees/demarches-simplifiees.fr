describe Champs::LinkedDropDownListChamp do
  describe '#unpack_value' do
    let(:champ) { build(:champ_linked_drop_down_list, value: '["tata", "tutu"]') }

    it { expect(champ.primary_value).to eq('tata') }
    it { expect(champ.secondary_value).to eq('tutu') }
  end

  describe '#pack_value' do
    let(:champ) { build(:champ_linked_drop_down_list, primary_value: 'tata', secondary_value: 'tutu') }

    before { champ.save }

    it { expect(champ.value).to eq('["tata","tutu"]') }
  end

  describe '#primary_value=' do
    let!(:champ) { build(:champ_linked_drop_down_list, primary_value: 'tata', secondary_value: 'tutu') }

    before { champ.primary_value = '' }

    it { expect(champ.value).to eq('["",""]') }
  end

  describe '#to_s' do
    let(:champ) { build(:champ_linked_drop_down_list, value: [primary_value, secondary_value].to_json) }
    let(:primary_value) { nil }
    let(:secondary_value) { nil }

    subject { champ.to_s }

    context 'with no value' do
      it { is_expected.to eq('') }
    end

    context 'with primary value' do
      let(:primary_value) { 'primary' }

      it { is_expected.to eq('primary') }
    end

    context 'with secondary value' do
      let(:primary_value) { 'primary' }
      let(:secondary_value) { 'secondary' }

      it { is_expected.to eq('primary / secondary') }
    end
  end

  describe 'for_export' do
    let(:champ) { build(:champ_linked_drop_down_list, value:) }
    let(:value) { [primary_value, secondary_value].to_json }
    let(:primary_value) { nil }
    let(:secondary_value) { nil }

    subject { champ.for_export }

    context 'with no value' do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end

    context 'with primary value' do
      let(:primary_value) { 'primary' }

      it { is_expected.to eq('primary;') }
    end

    context 'with secondary value' do
      let(:primary_value) { 'primary' }
      let(:secondary_value) { 'secondary' }

      it { is_expected.to eq('primary;secondary') }
    end
  end

  describe '#mandatory_and_blank' do
    let(:value) { "--Primary--\nSecondary" }

    subject { described_class.new(type_de_champ: type_de_champ) }

    context 'when the champ is not mandatory' do
      let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list, mandatory: false, drop_down_list_value: value) }

      it 'blank is fine' do
        is_expected.not_to be_mandatory_blank
      end
    end

    context 'when the champ is mandatory' do
      let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list, mandatory: true, drop_down_list_value: value) }

      context 'when there is no value' do
        it { is_expected.to be_mandatory_blank }
      end

      context 'when there is a primary value' do
        before { subject.primary_value = 'Primary' }

        context 'when there is no secondary value' do
          it { is_expected.to be_mandatory_blank }
        end

        context 'when there is a secondary value' do
          before { subject.secondary_value = 'Secondary' }

          it { is_expected.not_to be_mandatory_blank }
        end

        context 'when there is nothing to select for the secondary value' do
          let(:value) { "--A--\nAbbott\nAbelard\n--B--\n--C--\nCynthia" }
          before { subject.primary_value = 'B' }

          it { is_expected.not_to be_mandatory_blank }
        end
      end
    end
  end
end
