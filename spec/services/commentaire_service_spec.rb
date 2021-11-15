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
      let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }

      it 'attaches the file' do
        expect(commentaire.piece_jointe.attached?).to be_truthy
      end
    end
  end

  describe '.soft_delete' do
    subject { CommentaireService.soft_delete(user, params) }

    context 'when dossier not found' do
      let(:user) { create(:instructeur) }
      let(:params) { {} }
      it 'returns error struct' do
        expect(subject.status).to eq(false)
      end
      it 'returns error message' do
        expect(subject.error_message).to eq("Dossier introuvable")
      end
    end

    context 'when commentaire not found' do
      let(:user) { create(:instructeur) }
      let(:params) { { dossier_id: create(:dossier).id } }
      it 'returns error struct' do
        expect(subject.status).to eq(false)
      end
      it 'returns error message' do
        expect(subject.error_message).to eq("Commentaire introuvable")
      end
    end

    context 'when commentaire does not belongs to instructeur' do
      let(:user) { create(:instructeur) }
      let(:dossier) { create(:dossier) }
      let(:params) {
  {
    dossier_id: dossier.id,
                 id: create(:commentaire, dossier: dossier, instructeur: create(:instructeur)).id
  }
}
      it 'returns error struct' do
        expect(subject.status).to eq(false)
      end
      it 'returns error message' do
        expect(subject.error_message).to eq("Impossible de supprimer le message, celui ci ne vous appartient pas")
      end
    end

    context 'when commentaire belongs to instructeur' do
      let(:user) { create(:instructeur) }
      let(:dossier) { create(:dossier) }
      let(:commentaire) do
        create(:commentaire,
               dossier: dossier,
               instructeur: user,
               piece_jointe: fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf'))
      end
      let(:params) {
  {
    dossier_id: dossier.id,
                 id: commentaire.id
  }
}
      it 'returns error struct' do
        expect(subject.status).to eq(true)
      end
      it 'sets commentaire.body to deleted message' do
        allow(commentaire.piece_jointe).to receive(:purge_later)
        expect { subject }.to change { commentaire.reload.body }.from(an_instance_of(String)).to("Message supprimé")
      end
      it 'sets commentaire.body to deleted message' do
        expect { subject }.to change { commentaire.reload.body }.from(an_instance_of(String)).to("Message supprimé")
      end
      it 'sets deleted_at' do
        subject
        expect(commentaire.reload.deleted_at).not_to be_nil
      end
    end
  end
end
