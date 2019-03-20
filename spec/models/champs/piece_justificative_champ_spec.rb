describe Champs::PieceJustificativeChamp do
  describe '#for_api' do
    let(:champ_pj) { create(:champ_piece_justificative) }

    before { champ_pj.virus_scan.update(status: status) }

    subject { champ_pj.for_api }

    context 'when file is safe' do
      let(:status) { 'safe' }
      it { is_expected.to include("/rails/active_storage/blobs/") }
    end

    context 'when file is not scanned' do
      let(:status) { 'pending' }
      it { is_expected.to include("/rails/active_storage/blobs/") }
    end

    context 'when file is infected' do
      let(:status) { 'infected' }
      it { is_expected.to be_nil }
    end
  end
end
