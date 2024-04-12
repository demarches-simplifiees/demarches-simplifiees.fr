describe Champs::IntegerNumberChamp do
  let(:champ) { build(:champ_integer_number, value:) }
  subject { champ.validate(:champs_public_value) }

  describe '#valid?' do
    context 'when the value is integer number' do
      let(:value) { 2 }

      it { is_expected.to be_truthy }
    end

    context 'when the value is decimal number' do
      let(:value) { 2.6 }

      it 'is not valid and contains errors' do
        is_expected.to be_falsey
        expect(champ.errors[:value]).to eq(["doit être un nombre entier (sans chiffres après la virgule)"])
      end
    end

    context 'when the value is not a number' do
      let(:value) { 'toto' }

      it 'is not valid and contains errors' do
        is_expected.to be_falsey
        expect(champ.errors[:value]).to eq(["doit être un nombre entier (sans chiffres après la virgule)"])
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
  end
end
