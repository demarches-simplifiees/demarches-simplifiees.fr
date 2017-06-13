require 'spec_helper'

describe Users::Dossiers::CommentairesController, type: :controller do
  let(:dossier) { create(:dossier) }
  let(:texte_commentaire) { 'Commentaire de test' }

  describe '#POST create' do
    subject {
      post :create, params:{dossier_id: dossier.id, texte_commentaire: texte_commentaire}
      dossier.reload
    }

    context 'when invite is connected' do
      let!(:invite) { create(:invite, :with_user, dossier: dossier) }

      before do
        sign_in invite.user
        dossier.replied!
      end

      it do
        subject
        is_expected.to redirect_to users_dossiers_invite_path(invite.id)
        expect(dossier.state).to eq 'replied'
      end

      it 'should notify user' do
        expect(NotificationMailer).to receive(:new_answer).and_return(NotificationMailer)
        expect(NotificationMailer).to receive(:deliver_now!)

        subject
      end
    end

    context 'when user is connected' do
      before do
        sign_in dossier.user
      end

      it 'do not send a mail to notify user' do
        expect(NotificationMailer).to_not receive(:new_answer)
        subject
      end
    end
  end
end
