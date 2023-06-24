describe Champs::DgfipChamp, type: :model do
  let(:champ) { described_class.new }

  describe 'numero_fiscal and reference_avis' do
    before do
      champ.numero_fiscal = '1122299999092'
      champ.reference_avis = 'FC22299999092'
    end

    it 'saves numero_fiscal and reference_avis' do
      expect(champ.numero_fiscal).to eq('1122299999092')
      expect(champ.reference_avis).to eq('FC22299999092')
    end
  end

  describe 'external_id' do
    context 'when only one data is given' do
      before do
        champ.numero_fiscal = '1122299999092'
        champ.save
      end

      it { expect(champ.external_id).to be_nil }
    end

    context 'when all data required for an external fetch are given' do
      before do
        champ.numero_fiscal = '1122299999092'
        champ.reference_avis = 'FC22299999092'
        champ.save
      end

      it { expect(JSON.parse(champ.external_id)).to eq({ "reference_avis" => "FC22299999092", "numero_fiscal" => "1122299999092" }) }
    end
  end

  describe '#validate' do
    let(:numero_fiscal) { '1122299999092' }
    let(:reference_avis) { 'FC22299999092' }
    let(:champ) { described_class.new(dossier: create(:dossier), type_de_champ: create(:type_de_champ_dgfip)) }
    let(:validation_context) { :create }

    subject { champ.valid?(validation_context) }

    before do
      champ.numero_fiscal = numero_fiscal
      champ.reference_avis = reference_avis
    end

    context 'when numero_fiscal and reference_avis are valid' do
      it { is_expected.to be true }
    end

    context 'when numero_fiscal and reference_avis are nil' do
      let(:numero_fiscal) { nil }
      let(:reference_avis) { nil }

      it { is_expected.to be true }
    end

    context 'when only reference_avis is nil' do
      let(:reference_avis) { nil }

      it do
        is_expected.to be false
        expect(champ.errors.full_messages).to eq(["Le champ « Reference avis » doit posséder 13 ou 14 caractères"])
      end
    end

    context 'when only numero_fiscal is nil' do
      let(:numero_fiscal) { nil }

      it do
        is_expected.to be false
        expect(champ.errors.full_messages).to eq(["Le champ « Numero fiscal » doit posséder 13 ou 14 caractères"])
      end
    end

    context 'when numero_fiscal is invalid' do
      let(:numero_fiscal) { '11222' }

      it do
        is_expected.to be false
        expect(champ.errors.full_messages).to eq(["Le champ « Numero fiscal » doit posséder 13 ou 14 caractères"])
      end

      context 'and the validation_context is :brouillon' do
        let(:validation_context) { :brouillon }

        it { is_expected.to be true }
      end
    end

    context 'when reference_avis is invalid' do
      let(:reference_avis) { 'FC222' }

      it do
        is_expected.to be false
        expect(champ.errors.full_messages).to eq(["Le champ « Reference avis » doit posséder 13 ou 14 caractères"])
      end
    end
  end
end
