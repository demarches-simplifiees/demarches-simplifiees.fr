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
end
