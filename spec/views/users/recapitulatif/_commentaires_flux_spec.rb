require 'spec_helper'

describe 'users/recapitulatif/_commentaires_flux.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_procedure, :with_user) }
  let(:dossier_id) { dossier.id }
  let(:email_commentaire) { 'mon_mail_de_commentaire@test.com' }
  let!(:commentaire) { create(:commentaire, dossier: dossier, email: email_commentaire, body: 'ma super description') }
  let(:body) { 'Commentaire de test' }

  before do
    assign(:facade, DossierFacades.new(dossier.id, dossier.user.email))
    render
  end

  context 'Affichage du flux de commentaire' do
    it 'l\'email du contact est présent' do
      expect(rendered).to have_selector('span[id=email_contact]')
    end

    it 'la date du commentaire est présent' do
      expect(rendered).to have_selector('span[id=created_at]')
    end

    it 'le corps du commentaire est présent' do
      expect(rendered).to have_selector('div[class=description][id=body]')
    end
  end

  context 'Affichage du formulaire de commentaire' do
    it 'Le formulaire envoie vers /dossiers/:dossier_id/commentaire en #POST' do
      expect(rendered).to have_selector("form[action='/users/dossiers/#{dossier_id}/commentaire'][method=post]")
    end

    it 'Champs de texte' do
      expect(rendered).to have_selector('textarea[id=texte_commentaire][name=texte_commentaire]')
    end
  end
end
