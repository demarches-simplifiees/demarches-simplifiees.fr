require 'spec_helper'

describe CommentaireService do
  describe '.create' do
    let(:dossier) { create :dossier, :en_construction }
    let(:sender) { dossier.user }
    let(:body) { 'Contenu du message.' }
    let(:file) { nil }
    let(:scan_result) { true }

    subject(:commentaire) { CommentaireService.build(sender, dossier, { body: body, file: file }) }

    before do
      allow(ClamavService).to receive(:safe_file?).and_return(scan_result)
    end

    it 'creates a new valid commentaire' do
      expect(commentaire.email).to eq sender.email
      expect(commentaire.dossier).to eq dossier
      expect(commentaire.body).to eq 'Contenu du message.'
      expect(commentaire.file).to be_blank
      expect(commentaire).to be_valid
    end

    context 'when the body is empty' do
      let(:body) { nil }

      it 'creates an invalid comment' do
        expect(commentaire.body).to be nil
        expect(commentaire.valid?).to be false
      end
    end

    context 'when it has a file' do
      let(:file) { Rack::Test::UploadedFile.new("./spec/fixtures/files/piece_justificative_0.pdf", 'application/pdf') }

      it 'saves the attached file' do
        expect(commentaire.file).to be_present
        expect(commentaire).to be_valid
      end

      context 'and a virus' do
        let(:scan_result) { false }
        it { expect(commentaire).not_to be_valid }
      end
    end
  end
end
