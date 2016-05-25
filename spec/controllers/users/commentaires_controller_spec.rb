require 'spec_helper'

describe Users::CommentairesController, type: :controller do
  let(:dossier) { create(:dossier) }
  let(:dossier_id) { dossier.id }
  let(:email_commentaire) { 'test@test.com' }
  let(:texte_commentaire) { 'Commentaire de test' }

  before do
    allow(ClamavService).to receive(:safe_file?).and_return(true)
  end

  describe '#POST create' do
    context 'création correct d\'un commentaire' do
      subject do
        sign_in dossier.user
        post :create, dossier_id: dossier_id, texte_commentaire: texte_commentaire
      end

      it 'depuis la page récapitulatif' do
        subject
        expect(response).to redirect_to("/users/dossiers/#{dossier_id}/recapitulatif")
      end

      it 'Notification email is not send' do
        expect(NotificationMailer).not_to receive(:new_answer)
        expect(WelcomeMailer).not_to receive(:deliver_now!)

        subject
      end
    end

    context 'when document is upload whith a commentaire', vcr: { cassette_name: 'controllers_sers_commentaires_controller_upload_doc' } do
      let(:document_upload) { Rack::Test::UploadedFile.new("./spec/support/files/piece_justificative_0.pdf", 'application/pdf') }

      subject do
        sign_in dossier.user
        post :create, dossier_id: dossier_id, texte_commentaire: texte_commentaire, piece_justificative: {content: document_upload}
      end

      it 'create a new piece justificative' do
        expect { subject }.to change(PieceJustificative, :count).by(1)
      end

      it 'clamav check the pj' do
        expect(ClamavService).to receive(:safe_file?)
        subject
      end

      describe 'piece justificative created' do
        let(:pj) { PieceJustificative.last }

        before do
          subject
        end

        it 'not have a type de pj' do
          expect(pj.type_de_piece_justificative).to be_nil
        end

        it 'content not be nil' do
          expect(pj.content).not_to be_nil
        end
      end

      describe 'commentaire created' do
        let(:commentaire) { Commentaire.last }

        before do
          subject
        end

        it 'have a piece justificative reference' do
          expect(commentaire.piece_justificative).not_to be_nil
          expect(commentaire.piece_justificative).to eq PieceJustificative.last
        end
      end
    end

    describe 'change dossier state after post a comment' do
      context 'when user is connected' do
        context 'when dossier is at state replied' do
          before do
            sign_in dossier.user
            dossier.replied!

            post :create, dossier_id: dossier_id, texte_commentaire: texte_commentaire
            dossier.reload
          end

          subject { dossier.state }

          it { is_expected.to eq('updated') }
        end
      end
    end
  end
end
