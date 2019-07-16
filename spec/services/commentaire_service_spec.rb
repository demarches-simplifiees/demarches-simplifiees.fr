require 'spec_helper'

describe CommentaireService do
  include ActiveJob::TestHelper

  describe '.create' do
    let(:dossier) { create :dossier, :en_construction }
    let(:sender) { dossier.user }
    let(:body) { 'Contenu du message.' }
    let(:file) { nil }

    subject(:commentaire) { CommentaireService.build(sender, dossier, { body: body, piece_jointe: file }) }

    it 'creates a new valid commentaire' do
      expect(commentaire.email).to eq sender.email
      expect(commentaire.dossier).to eq dossier
      expect(commentaire.body).to eq 'Contenu du message.'
      expect(commentaire.piece_jointe.attached?).to be_falsey
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

      before do
        expect(ClamavService).to receive(:safe_file?).and_return(true)
      end

      it 'saves the attached file' do
        perform_enqueued_jobs do
          commentaire.save
          expect(commentaire.piece_jointe.attached?).to be_truthy
        end
      end
    end
  end
end
