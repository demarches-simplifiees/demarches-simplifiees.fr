describe Champs::DecimalNumberChamp do
  subject { build(:champ_decimal_number, value: value).tap(&:valid?) }

  describe '#valid?' do
    context 'when the value is integer number' do
      let(:value) { 2 }

      it { is_expected.to be_valid }
    end

    context 'when the value is decimal number' do
      let(:value) { 2.6 }

      it { is_expected.to be_valid }
    end

    context 'when the value is not a number' do
      let(:value) { 'toto' }

      it { is_expected.to_not be_valid }
      it { expect(subject.errors[:value]).to eq(["« #{subject.libelle} » doit comprendre maximum 3 chiffres après la virgule", "« #{subject.libelle} » n'est pas un nombre"]) }
    end

    context 'when the value has too many decimal' do
      let(:value) { '2.6666' }

      it { is_expected.to_not be_valid }
      it { expect(subject.errors[:value]).to eq(["« #{subject.libelle} » doit comprendre maximum 3 chiffres après la virgule"]) }
    end

    context 'when the value is blank' do
      let(:value) { '' }

      it { is_expected.to be_valid }
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it { is_expected.to be_valid }
    end
  end
end
