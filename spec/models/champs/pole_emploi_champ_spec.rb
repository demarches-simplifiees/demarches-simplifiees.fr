describe Champs::PoleEmploiChamp, type: :model do
  let(:champ) { described_class.new(dossier: build(:dossier)) }
  before { allow(champ).to receive(:type_de_champ).and_return(:type_de_champ_pole_emploi) }

  describe 'identifiant' do
    before do
      champ.identifiant = 'georges_moustaki_77'
    end

    it 'saves identifiant' do
      expect(champ.identifiant).to eq('georges_moustaki_77')
    end
  end

  describe 'external_id' do
    context 'when no data is given' do
      before do
        champ.identifiant = ''
        champ.save
      end

      it { expect(champ.external_id).to be_nil }
    end

    context 'when all data required for an external fetch are given' do
      before do
        champ.identifiant = 'georges_moustaki_77'
        champ.save
      end

      it { expect(JSON.parse(champ.external_id)).to eq("identifiant" => "georges_moustaki_77") }
    end
  end

  describe '#validate' do
    let(:validation_context) { :create }

    subject { champ.valid?(validation_context) }

    before do
      champ.identifiant = identifiant
    end

    context 'when identifiant is valid' do
      let(:identifiant) { 'georges_moustaki_77' }

      it { is_expected.to be true }
    end

    context 'when identifiant is nil' do
      let(:identifiant) { nil }

      it { is_expected.to be true }
    end
  end
end
