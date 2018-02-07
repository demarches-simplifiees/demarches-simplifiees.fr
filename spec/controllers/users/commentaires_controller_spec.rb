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
    context "when user has no access to dossier" do
      before do
        sign_in create(:user)
      end
      subject { post :create, params: { dossier_id: dossier_id, texte_commentaire: texte_commentaire } }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
      it { expect { subject rescue nil }.to change(Commentaire, :count).by(0) }
    end

    context "when user is invited on dossier" do
      let(:user) { create(:user) }
      subject { post :create, params: { dossier_id: dossier_id, texte_commentaire: texte_commentaire } }

      before do
        sign_in user
        InviteUser.create(dossier: dossier, user: user, email: user.email, email_sender: "test@test.com")
      end

      it { expect{ subject }.to change(Commentaire, :count).by(1) }
    end

    context 'création correct d\'un commentaire' do
      subject do
        sign_in dossier.user
        post :create, params: { dossier_id: dossier_id, texte_commentaire: texte_commentaire }
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
        post :create, params: { dossier_id: dossier_id, texte_commentaire: texte_commentaire, file: document_upload }
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
          expect(commentaire.file.present?).to be true
          expect(commentaire.file.class).to eq CommentaireFileUploader
        end
      end
    end
  end
end
