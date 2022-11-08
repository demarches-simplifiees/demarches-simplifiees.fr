describe Champs::TitreIdentiteChamp do
  describe "#for_export" do
    let(:champ_titre_identite) { create(:champ_titre_identite) }

    subject { champ_titre_identite.for_export }

    it { is_expected.to eq('présent') }

    context 'without attached file' do
      before { champ_titre_identite.piece_justificative_file.purge }
      it { is_expected.to eq('absent') }
    end
  end

  describe '#for_api' do
    let(:champ_titre_identite) { create(:champ_titre_identite) }

    subject { champ_titre_identite.for_api }

    it { is_expected.to eq('présent') }

    context 'without attached file' do
      before { champ_titre_identite.piece_justificative_file.purge }
      it { is_expected.to eq('absent') }
    end
  end
end
