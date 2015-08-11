require 'spec_helper'

describe CommentairesController, type: :controller do
  let (:dossier_id){10000}
  let (:email_commentaire){'test@test.com'}
  let (:texte_commentaire){'Commentaire de test'}

  describe '#POST create' do
    context 'création correct d\'un commentaire' do
      it 'depuis la page récapitulatif' do
        request.env["HTTP_REFERER"] = "/recapitulatif"
        post :create, :dossier_id => dossier_id, :email_commentaire => email_commentaire, :texte_commentaire => texte_commentaire
        expect(response).to redirect_to("/dossiers/#{dossier_id}/recapitulatif")
      end

      it 'depuis la page admin' do
        request.env["HTTP_REFERER"] = "/admin/dossier"
        post :create, :dossier_id => dossier_id, :email_commentaire => email_commentaire, :texte_commentaire => texte_commentaire
        expect(response).to redirect_to("/admin/dossier/#{dossier_id}")
      end
    end
  end
end
