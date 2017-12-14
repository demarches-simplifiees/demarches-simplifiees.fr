require 'spec_helper'

describe Backoffice::CommentairesController, type: :controller do
  let(:dossier) { create(:dossier, :en_construction) }
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

    context "when gestionnaire has no access to dossier" do
      subject { post :create, params: { dossier_id: dossier_id, texte_commentaire: texte_commentaire } }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
      it { expect { subject rescue nil }.to change(Commentaire, :count).by(0) }
    end

    context "when gestionnaire is invited for avis on dossier" do
      subject { post :create, params: { dossier_id: dossier_id, texte_commentaire: texte_commentaire } }
      before { Avis.create(dossier: dossier, gestionnaire: gestionnaire, claimant: create(:gestionnaire)) }

      it { expect{ subject }.to change(Commentaire, :count).by(1) }
    end

    context "when gestionnaire has access to dossier" do
      before do
        gestionnaire.procedures << dossier.procedure
      end

      context "création correct d'un commentaire" do
        subject { post :create, params: {dossier_id: dossier_id, email_commentaire: email_commentaire, texte_commentaire: texte_commentaire} }

        it 'depuis la page admin' do
          expect(subject).to redirect_to("/backoffice/dossiers/#{dossier_id}")
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

        it 'Internal notification is not create' do
          expect { subject }.to change(Notification, :count).by (0)
        end
      end

      context 'when document is upload whith a commentaire', vcr: {cassette_name: 'controllers_backoffice_commentaires_controller_doc_upload_with_comment'} do
        let(:document_upload) { Rack::Test::UploadedFile.new("./spec/support/files/piece_justificative_0.pdf", 'application/pdf') }

        subject do
          post :create, params: { dossier_id: dossier_id, email_commentaire: email_commentaire, texte_commentaire: texte_commentaire, file: document_upload }
        end

        it 'clamav check the pj' do
          expect(ClamavService).to receive(:safe_file?)
          subject
        end

        describe 'commentaire created' do
          let(:commentaire) { Commentaire.last }

          before do
            subject
          end

          it 'have a piece justificative reference' do
            expect(commentaire.file.present?).to eq true
            expect(commentaire.file.class).to eq(CommentaireFileUploader)
          end
        end
      end

      describe 'change dossier state after post a comment' do
        context 'gestionnaire is connected' do
          context 'when dossier is at state en_construction' do
            before do
              sign_in gestionnaire
              dossier.en_construction!

              post :create, params: {dossier_id: dossier_id, texte_commentaire: texte_commentaire}
              dossier.reload
            end

            it 'Notification email is send' do
              expect(NotificationMailer).to receive(:new_answer).and_return(NotificationMailer)
              expect(NotificationMailer).to receive(:deliver_now!)

              post :create, params: {dossier_id: dossier_id, texte_commentaire: texte_commentaire}
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

          post :create, params: {dossier_id: dossier_id, texte_commentaire: texte_commentaire}
        end
      end
    end
  end
end
