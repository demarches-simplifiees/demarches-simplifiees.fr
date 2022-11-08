describe ClonePieceJustificativeJob, type: :job do
  describe 'perform' do
    let(:dossier_from) { create(:dossier) }
    let(:dossier_to) { create(:dossier, procedure: dossier_from.procedure) }
    let(:champ_piece_justificative_from) { create(:champ, :with_piece_justificative_file, dossier_id: dossier_from.id) }
    let(:champ_piece_justificative_to) { create(:champ_without_piece_justificative, dossier_id: dossier_to.id, piece_justificative_file: nil) }

    it 'creates a piece_justificative_file' do
      expect {
        ClonePieceJustificativeJob.perform_now(champ_piece_justificative_from, champ_piece_justificative_to)
      }.to change { champ_piece_justificative_to.piece_justificative_file.blob }.from(nil).to an_instance_of(ActiveStorage::Blob)
    end
    it 'creates a piece_justificative_file' do
      ClonePieceJustificativeJob.perform_now(champ_piece_justificative_from, champ_piece_justificative_to)
      expect(champ_piece_justificative_to.piece_justificative_file.blob.download)
        .to eq(champ_piece_justificative_from.piece_justificative_file.blob.download)
    end
  end
end
