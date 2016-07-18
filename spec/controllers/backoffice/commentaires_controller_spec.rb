require 'spec_helper'

describe Backoffice::CommentairesController, type: :controller do
  let(:dossier) { create(:dossier) }
  let(:dossier_id) { dossier.id }
  let(:email_commentaire) { 'test@test.com' }
  let(:texte_commentaire) { 'Commentaire de test' }
  let(:gestionnaire) { create(:gestionnaire) }

  before do
    allow(ClamavService).to receive(:safe_file?).and_return(true)
  end

  describe '#POST create' do
    before do
      sign_in gestionnaire
    end

    context "création correct d'un commentaire" do
      subject { post :create, dossier_id: dossier_id, email_commentaire: email_commentaire, texte_commentaire: texte_commentaire }

      it 'depuis la page admin' do
        expect(response).to redirect_to("/backoffice/dossiers/#{dossier_id}")
      end

      it 'gestionnaire is automatically affect to follow the dossier' do
        expect { subject }.to change(Follow, :count).by(1)
      end

      context 'when gestionnaire already follow dossier' do
        before do
          create :follow, gestionnaire_id: gestionnaire.id, dossier_id: dossier_id
        end

        it 'gestionnaire is automatically affect to follow the dossier' do
          expect { subject }.to change(Follow, :count).by(0)
        end
      end
    end

    context 'when document is upload whith a commentaire', vcr: {cassette_name: 'controllers_backoffice_commentaires_controller_doc_upload_with_comment'} do
      let(:document_upload) { Rack::Test::UploadedFile.new("./spec/support/files/piece_justificative_0.pdf", 'application/pdf') }

      subject do
        post :create, dossier_id: dossier_id, email_commentaire: email_commentaire, texte_commentaire: texte_commentaire, piece_justificative: {content: document_upload}
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
      context 'gestionnaire is connected' do
        context 'when dossier is at state updated' do
          before do
            sign_in create(:gestionnaire)
            dossier.updated!

            post :create, dossier_id: dossier_id, texte_commentaire: texte_commentaire
            dossier.reload
          end

          subject { dossier.state }

          it { is_expected.to eq('replied') }

          it 'Notification email is send' do
            expect(NotificationMailer).to receive(:new_answer).and_return(NotificationMailer)
            expect(NotificationMailer).to receive(:deliver_now!)

            post :create, dossier_id: dossier_id, texte_commentaire: texte_commentaire
          end
        end
      end
    end

    describe 'comment cannot be saved' do
      before do
        allow_any_instance_of(Commentaire).to receive(:save).and_return(false)
      end
      it 'Notification email is not sent' do
        expect(NotificationMailer).not_to receive(:new_answer)
        expect(NotificationMailer).not_to receive(:deliver_now!)

        post :create, dossier_id: dossier_id, texte_commentaire: texte_commentaire
      end
    end
  end
end
