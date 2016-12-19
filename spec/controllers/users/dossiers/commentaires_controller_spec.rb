require 'spec_helper'

describe Users::Dossiers::CommentairesController, type: :controller do
  let(:dossier) { create(:dossier) }
  let(:texte_commentaire) { 'Commentaire de test' }

  describe '#POST create' do
    context 'when invite is connected' do
      let!(:invite) { create(:invite, :with_user, dossier: dossier) }

      before do
        sign_in invite.user
        dossier.replied!

        post :create, params:{dossier_id: dossier.id, texte_commentaire: texte_commentaire}
        dossier.reload
      end

      it { is_expected.to redirect_to users_dossiers_invite_path(invite.id) }
      it { expect(dossier.state).to eq 'replied' }
    end
  end
end
