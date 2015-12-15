require 'spec_helper'

describe Backoffice::CommentairesController, type: :controller do
  let(:dossier) { create(:dossier, :with_user) }
  let(:dossier_id) { dossier.id }
  let(:email_commentaire) { 'test@test.com' }
  let(:texte_commentaire) { 'Commentaire de test' }

  describe '#POST create' do
    before do
      sign_in create(:gestionnaire)
    end
    context "création correct d'un commentaire" do
      it 'depuis la page admin' do
        post :create, dossier_id: dossier_id, email_commentaire: email_commentaire, texte_commentaire: texte_commentaire
        expect(response).to redirect_to("/backoffice/dossiers/#{dossier_id}")
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

          it {is_expected.to eq('replied')}

          it 'Notification email is send' do
            expect(NotificationMailer).to receive(:new_answer).and_return(NotificationMailer)
            expect(NotificationMailer).to receive(:deliver_now!)

            post :create, dossier_id: dossier_id, texte_commentaire: texte_commentaire
          end
        end
      end
    end
  end
end
