describe Champs::MultipleDropDownListChamp do
  let(:type_de_champ) { build(:type_de_champ_multiple_drop_down_list, drop_down_list_value: "val1\r\nval2\r\nval3") }
  let(:value) { nil }
  subject { build(:champ_multiple_drop_down_list, type_de_champ:, value:) }

  describe 'validations' do
    describe 'inclusion' do
      context 'when the value is nil' do
        it { is_expected.to be_valid }
      end

      context 'when the value is an empty string' do
        let(:value) { '' }

        it { is_expected.to be_valid }
      end

      context 'when the value is an empty array' do
        let(:value) { [] }

        it { is_expected.to be_valid }
      end

      context 'when the value is included in the option list' do
        let(:value) { ["val3", "val1"] }

        it { is_expected.to be_valid }
      end

      context 'when the value is not included in the option list' do
        let(:value) { ["totoro", "val1"] }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe '#next_checkbox_id' do
    let(:value) { ["val1", "val2", "val3"] }

    context 'when the value has next value' do
      it {
        expect(subject.next_checkbox_id("val1")).to eq(subject.checkbox_id("val2"))
        expect(subject.next_checkbox_id("val2")).to eq(subject.checkbox_id("val3"))
      }
    end

    context 'when the value is last' do
      it { expect(subject.next_checkbox_id("val3")).to eq(subject.checkbox_id("val2")) }
    end

    context 'when the value is invalid' do
      it { expect(subject.next_checkbox_id("val4")).to eq(nil) }
    end

    context 'when the values are empty' do
      let(:value) { [] }
      it { expect(subject.next_checkbox_id("val1")).to eq(nil) }
    end
  end
end
