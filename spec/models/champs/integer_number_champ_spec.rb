# frozen_string_literal: true

describe Champs::IntegerNumberChamp do
  let(:champ) { Champs::IntegerNumberChamp.new(value:, dossier: build(:dossier)) }
  before do
    allow(champ).to receive(:visible?).and_return(true)
    allow(champ).to receive(:can_validate?).and_return(true)
  end
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

    context 'when the value is a number with sapces' do
      let(:value) { ' 120 ' }

      it 'is valid and is formated' do
        is_expected.to be_truthy
        champ.save!
        expect(champ.value).to eq('120')
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
