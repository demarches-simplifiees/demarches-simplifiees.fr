describe Champs::NumbersAndLettersIdChamp do
  let(:champ) { Champs::NumbersAndLettersIdChamp.new(value:, dossier: build(:dossier)) }
  before { allow(champ).to receive(:visible?).and_return(true) }
  subject { champ.validate(:champs_public_value) }

  describe '#valid?' do
    context 'when the value is string with numbers and letters' do
      let(:value) { "KA29787" }

      it { is_expected.to be_truthy }
    end

    context 'when the value is string starting with 0' do
      let(:value) { "029787KA" }

      it { is_expected.to be_truthy }
      it 'contains 0' do
        expect(champ.value).to eq '029787KA'
      end
    end

    context 'when the value is decimal number' do
      let(:value) { 2.6 }

      it 'is not valid and contains errors' do
        is_expected.to be_falsey
        expect(champ.errors[:value]).to eq(["doit contenir uniquement des chiffres et des lettres"])
      end
    end

    context 'when the value is not only numbers or letters' do
      let(:value) { 'toto2:r' }

      it 'is not valid and contains errors' do
        is_expected.to be_falsey
        expect(champ.errors[:value]).to eq(["doit contenir uniquement des chiffres et des lettres"])
      end
    end

    context 'when the value contains spaces' do
      let(:value) { ' 120rA ' }

      it 'is valid and is formated' do
        is_expected.to be_truthy
        champ.save!
        expect(champ.value).to eq('120rA')
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
