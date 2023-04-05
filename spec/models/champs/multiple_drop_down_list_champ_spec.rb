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
end
