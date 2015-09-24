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
  end
end
