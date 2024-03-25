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

    context 'when it has multiple files' do
      let(:files) do
        [
          fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf')
        ]
      end

      before do
        commentaire.piece_jointe.attach(files)
      end

      it 'attaches the files' do
        expect(commentaire.piece_jointe.attached?).to be_truthy
        expect(commentaire.piece_jointe.count).to eq(1)
      end
    end
  end
end
