describe 'shared/attachment/_show.html.haml', type: :view do
  let(:champ) { create(:champ_piece_justificative) }
  let(:virus_scan_result) { nil }

  before do
    champ.piece_justificative_file[0].blob.update(metadata: champ.piece_justificative_file[0].blob.metadata.merge(virus_scan_result: virus_scan_result))
  end

  subject { render Attachment::ShowComponent.new(attachment: champ.piece_justificative_file.attachments.first) }

  context 'when there is no anti-virus scan' do
    let(:virus_scan_result) { nil }

    it 'allows to download the file' do
      expect(subject).to have_link(champ.piece_justificative_file[0].filename.to_s)
      expect(subject).to have_text('ce fichier n’a pas été analysé par notre antivirus')
    end
  end

  context 'when the anti-virus scan is pending' do
    let(:virus_scan_result) { ActiveStorage::VirusScanner::PENDING }

    it 'displays the filename, but doesn’t allow to download the file' do
      expect(subject).to have_text(champ.piece_justificative_file[0].filename.to_s)
      expect(subject).not_to have_link(champ.piece_justificative_file[0].filename.to_s)
      expect(subject).to have_text('analyse antivirus en cours')
    end
  end

  context 'when watermark is pending' do
    let(:champ) { create(:champ_titre_identite) }

    it 'displays the filename, but doesn’t allow to download the file' do
      expect(champ.piece_justificative_file.attachments[0].watermark_pending?).to be_truthy
      expect(subject).to have_text(champ.piece_justificative_file[0].filename.to_s)
      expect(subject).not_to have_link(champ.piece_justificative_file[0].filename.to_s)
      expect(subject).to have_text('traitement de la pièce en cours')
    end
  end

  context 'when the file is scanned and safe' do
    let(:virus_scan_result) { ActiveStorage::VirusScanner::SAFE }

    it 'allows to download the file' do
      expect(subject).to have_link(champ.piece_justificative_file[0].filename.to_s)
    end
  end

  context 'when the file is scanned and infected' do
    let(:virus_scan_result) { ActiveStorage::VirusScanner::INFECTED }

    it 'displays the filename, but doesn’t allow to download the file' do
      expect(subject).to have_text(champ.piece_justificative_file[0].filename.to_s)
      expect(subject).not_to have_link(champ.piece_justificative_file[0].filename.to_s)
      expect(subject).to have_text('virus détecté')
    end
  end

  context 'when the file is corrupted' do
    let(:virus_scan_result) { ActiveStorage::VirusScanner::INTEGRITY_ERROR }

    it 'displays the filename, but doesn’t allow to download the file' do
      expect(subject).to have_text(champ.piece_justificative_file[0].filename.to_s)
      expect(subject).not_to have_link(champ.piece_justificative_file[0].filename.to_s)
      expect(subject).to have_text('corrompu')
    end
  end
end
