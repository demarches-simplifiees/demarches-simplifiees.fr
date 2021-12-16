describe Champs::MesriChamp, type: :model do
  let(:champ) { described_class.new }

  describe 'INE' do
    before do
      champ.ine = '090601811AB'
    end

    it 'saves INE' do
      expect(champ.ine).to eq('090601811AB')
    end
  end

  describe 'external_id' do
    context 'when no data is given' do
      before do
        champ.ine = ''
        champ.save
      end

      it { expect(champ.external_id).to be_nil }
    end

    context 'when all data required for an external fetch are given' do
      before do
        champ.ine = '090601811AB'
        champ.save
      end

      it { expect(JSON.parse(champ.external_id)).to eq("ine" => "090601811AB") }
    end
  end

  describe '#validate' do
    let(:champ) { described_class.new(dossier: create(:dossier), type_de_champ: create(:type_de_champ_mesri)) }
    let(:validation_context) { :create }

    subject { champ.valid?(validation_context) }

    before do
      champ.ine = ine
    end

    context 'when INE is valid' do
      let(:ine) { '090601811AB' }

      it { is_expected.to be true }
    end

    context 'when INE is nil' do
      let(:ine) { nil }

      it { is_expected.to be true }
    end
  end
end
