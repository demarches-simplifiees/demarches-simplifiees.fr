describe Champs::CnafChamp, type: :model do
  let(:champ) { described_class.new }

  describe 'numero_allocataire and code_postal' do
    before do
      champ.numero_allocataire = '1234567'
      champ.code_postal = '12345'
    end

    it 'saves numero_allocataire and code_postal' do
      expect(champ.numero_allocataire).to eq('1234567')
      expect(champ.code_postal).to eq('12345')
    end
  end

  describe 'external_id' do
    context 'when only one data is given' do
      before do
        champ.numero_allocataire = '1234567'
        champ.save
      end

      it { expect(champ.external_id).to be_nil }
    end

    context 'when all data required for an external fetch are given' do
      before do
        champ.numero_allocataire = '1234567'
        champ.code_postal = '12345'
        champ.save
      end

      it { expect(JSON.parse(champ.external_id)).to eq({ "code_postal" => "12345", "numero_allocataire" => "1234567" }) }
    end
  end

  describe '#validate' do
    let(:numero_allocataire) { '1234567' }
    let(:code_postal) { '12345' }
    let(:champ) { described_class.new(dossier: create(:dossier), type_de_champ: create(:type_de_champ_cnaf)) }
    let(:validation_context) { :create }

    subject { champ.valid?(validation_context) }

    before do
      champ.numero_allocataire = numero_allocataire
      champ.code_postal = code_postal
    end

    context 'when numero_allocataire and code_postal are valids' do
      it { is_expected.to be true }
    end

    context 'when numero_allocataire and code_postal are nil' do
      let(:numero_allocataire) { nil }
      let(:code_postal) { nil }

      it { is_expected.to be true }
    end

    context 'when only code_postal is nil' do
      let(:code_postal) { nil }

      it do
        is_expected.to be false
        expect(champ.errors.full_messages).to eq(["Le champ « Code postal » doit posséder 5 caractères"])
      end
    end

    context 'when only numero_allocataire is nil' do
      let(:numero_allocataire) { nil }

      it do
        is_expected.to be false
        expect(champ.errors.full_messages).to eq(["Le champ « Numero allocataire » doit être composé au maximum de 7 chiffres"])
      end
    end

    context 'when numero_allocataire is invalid' do
      let(:numero_allocataire) { '123456a' }

      it do
        is_expected.to be false
        expect(champ.errors.full_messages).to eq(["Le champ « Numero allocataire » doit être composé au maximum de 7 chiffres"])
      end

      context 'and the validation_context is :brouillon' do
        let(:validation_context) { :brouillon }

        it { is_expected.to be true }
      end
    end

    context 'when code_postal is invalid' do
      let(:code_postal) { '123456' }

      it do
        is_expected.to be false
        expect(champ.errors.full_messages).to eq(["Le champ « Code postal » doit posséder 5 caractères"])
      end
    end
  end
end
