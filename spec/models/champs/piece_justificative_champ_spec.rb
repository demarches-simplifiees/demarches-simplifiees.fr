describe Champs::PieceJustificativeChamp do
  describe '#for_api' do
    let(:champ_pj) { create(:champ_piece_justificative) }
    let(:metadata) { champ_pj.piece_justificative_file.blob.metadata }

    before { champ_pj.piece_justificative_file.blob.update(metadata: metadata.merge(virus_scan_result: status)) }

    subject { champ_pj.for_api }

    context 'when file is safe' do
      let(:status) { ActiveStorage::VirusScanner::SAFE }
      it { is_expected.to include("/rails/active_storage/blobs/") }
    end

    context 'when file is not scanned' do
      let(:status) { ActiveStorage::VirusScanner::PENDING }
      it { is_expected.to include("/rails/active_storage/blobs/") }
    end

    context 'when file is infected' do
      let(:status) { ActiveStorage::VirusScanner::INFECTED }
      it { is_expected.to be_nil }
    end
  end
end
