describe Champs::TitreIdentiteChamp do
  describe "#for_export" do
    let(:champ) { described_class.new }
    before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_titre_identite)) }
    subject { champ.for_export }

    context 'without attached file' do
      let(:piece_justificative_file) { double(attached?: true) }
      before { allow(champ).to receive(:piece_justificative_file).and_return(piece_justificative_file) }
      it { is_expected.to eq('présent') }
    end

    context 'without attached file' do
      it { is_expected.to eq('absent') }
    end
  end
end
