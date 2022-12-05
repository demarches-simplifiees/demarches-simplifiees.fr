RSpec.describe Attachment::ShowComponent, type: :component do
  let(:champ) { create(:champ_piece_justificative) }
  let(:virus_scan_result) { nil }

  let(:attachment) {
    champ.piece_justificative_file.attachments.first
  }

  let(:filename) { attachment.filename.to_s }

  let(:component) do
    described_class.new(attachment:)
  end

  subject { render_inline(component).to_html }

  before do
    champ.piece_justificative_file[0].blob.update(metadata: champ.piece_justificative_file[0].blob.metadata.merge(virus_scan_result: virus_scan_result))
  end

  context 'when there is no anti-virus scan' do
    let(:virus_scan_result) { nil }

    it 'allows to download the file' do
      expect(subject).to have_link(filename)
      expect(subject).to have_text('ce fichier n’a pas été analysé par notre antivirus')
    end
  end

  context 'when the anti-virus scan is pending' do
    let(:virus_scan_result) { ActiveStorage::VirusScanner::PENDING }

    it 'displays the filename, but doesn’t allow to download the file' do
      expect(subject).to have_text(filename)
      expect(subject).not_to have_link(filename)
      expect(subject).to have_text('Analyse antivirus en cours')
    end
  end

  context 'when the file is scanned and safe' do
    let(:virus_scan_result) { ActiveStorage::VirusScanner::SAFE }

    it 'allows to download the file' do
      expect(subject).to have_link(filename)
    end
  end

  context 'when the file is scanned and infected' do
    let(:virus_scan_result) { ActiveStorage::VirusScanner::INFECTED }

    it 'displays the filename, but doesn’t allow to download the file' do
      expect(subject).to have_text(filename)
      expect(subject).not_to have_link(filename)
      expect(subject).to have_text('Virus détecté')
    end
  end

  context 'when the file is corrupted' do
    let(:virus_scan_result) { ActiveStorage::VirusScanner::INTEGRITY_ERROR }

    it 'displays the filename, but doesn’t allow to download the file' do
      expect(subject).to have_text(filename)
      expect(subject).not_to have_link(filename)
      expect(subject).to have_text('corrompu')
    end
  end
end
