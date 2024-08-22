# frozen_string_literal: true

describe Champs::DecimalNumberChamp do
  describe 'validation' do
    let(:champ) { Champs::DecimalNumberChamp.new(value:, dossier: build(:dossier)) }
    before do
      allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_decimal_number))
      allow(champ).to receive(:visible?).and_return(true)
      allow(champ).to receive(:in_dossier_revision?).and_return(true)
      champ.run_callbacks(:validation)
    end
    subject { champ.validate(:champs_public_value) }

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

    context 'when value contain space' do
      before { champ.run_callbacks(:validation) }
      let(:value) { ' 2.6666 ' }
      it { expect(champ.value).to eq('2.6666') }
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
      let(:champ) { Champs::DecimalNumberChamp.new(value:, private: true, dossier: build(:dossier)) }
      let(:value) { '2.6666' }
      it { is_expected.to be_truthy }
    end
  end

  describe 'for_export' do
    let(:champ) { Champs::DecimalNumberChamp.new(value:) }
    before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_decimal_number)) }
    subject { champ.for_export }
    context 'with nil' do
      let(:value) { 0 }
      it { is_expected.to eq(0.0) }
    end
    context 'with simple number' do
      let(:value) { "120" }
      it { is_expected.to eq(120) }
    end
    context 'with number having spaces' do
      let(:value) { " 120 " }
      it { is_expected.to eq(120) }
    end
  end
end
