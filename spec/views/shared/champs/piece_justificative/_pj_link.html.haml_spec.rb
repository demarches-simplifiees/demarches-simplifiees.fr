require 'rails_helper'

describe 'shared/champs/piece_justificative/_pj_link.html.haml', type: :view do
  let(:champ) { create(:champ, :piece_justificative, :with_piece_justificative_file) }
  let(:virus_scan) { nil }

  before do
    if virus_scan
      champ.update(virus_scan: virus_scan)
    end
  end

  subject { render 'shared/champs/piece_justificative/pj_link', champ: champ, user_can_upload: false }

  context 'when there is no anti-virus scan' do
    let(:virus_scan) { nil }

    it 'allows to download the file' do
      expect(subject).to have_link(champ.piece_justificative_file.filename.to_s)
      expect(subject).to have_text('ce fichier n’a pas été analysé par notre antivirus')
    end
  end

  context 'when the anti-virus scan is pending' do
    let(:virus_scan) { create(:virus_scan, :pending) }

    it 'displays the filename, but doesn’t allow to download the file' do
      expect(subject).to have_text(champ.piece_justificative_file.filename.to_s)
      expect(subject).not_to have_link(champ.piece_justificative_file.filename.to_s)
      expect(subject).to have_text('analyse antivirus en cours')
    end
  end

  context 'when the file is scanned and safe' do
    let(:virus_scan) { create(:virus_scan, :safe) }

    it 'allows to download the file' do
      expect(subject).to have_link(champ.piece_justificative_file.filename.to_s)
    end
  end

  context 'when the file is scanned and infected' do
    let(:virus_scan) { create(:virus_scan, :infected) }

    it 'displays the filename, but doesn’t allow to download the file' do
      expect(subject).to have_text(champ.piece_justificative_file.filename.to_s)
      expect(subject).not_to have_link(champ.piece_justificative_file.filename.to_s)
      expect(subject).to have_text('virus détecté')
    end
  end
end
