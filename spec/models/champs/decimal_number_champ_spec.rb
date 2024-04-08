describe Champs::DecimalNumberChamp do
  let(:champ) { build(:champ_decimal_number, value:) }
  subject { champ.validate(:champs_public_value) }

  describe 'validation' do
    context 'when the value is integer number' do
      let(:value) { 2 }

      it { is_expected.to be_truthy }
    end

    context 'when the value is decimal number' do
      let(:value) { 2.6 }

      it { is_expected.to be_truthy }
    end

    context 'when the value is not a number' do
      let(:value) { 'toto' }

      it 'is not valid and contains expected error' do
        expect(subject).to be_falsey
        expect(champ.errors[:value]).to eq(["doit comprendre maximum 3 chiffres après la virgule", "n'est pas un nombre"])
      end
    end

    context 'when the value has too many decimal' do
      let(:value) { '2.6666' }

      it 'is not valid and contains expected error' do
        expect(subject).to be_falsey
        expect(champ.errors[:value]).to eq(["doit comprendre maximum 3 chiffres après la virgule"])
      end
    end

    context 'when the value is blank' do
      let(:value) { '' }

      it { is_expected.to be_truthy }
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it { is_expected.to be_truthy }
    end

    context 'when the champ is private, value is invalid, but validation is public' do
      let(:champ) { build(:champ_decimal_number, :private, value:) }
      let(:value) { '2.6666' }
      it { is_expected.to be_truthy }
    end
  end
end
