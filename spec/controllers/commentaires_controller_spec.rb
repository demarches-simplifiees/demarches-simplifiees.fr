require 'spec_helper'

describe Users::CommentairesController, type: :controller do
  let(:dossier) { create(:dossier, :with_user) }
  let(:dossier_id) { dossier.id }
  let(:email_commentaire) { 'test@test.com' }
  let(:texte_commentaire) { 'Commentaire de test' }

  describe '#POST create' do
    context 'création correct d\'un commentaire' do
      it 'depuis la page récapitulatif' do
        sign_in dossier.user
        post :create, dossier_id: dossier_id, email_commentaire: email_commentaire, texte_commentaire: texte_commentaire
        expect(response).to redirect_to("/users/dossiers/#{dossier_id}/recapitulatif")
      end
    end
  end
end
