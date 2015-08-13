require 'spec_helper'

feature '_Commentaires_Flux Recapitulatif#Show Page' do
  let(:dossier) { create(:dossier) }
  let(:dossier_id) { dossier.id }
  let(:email_commentaire) { 'mon_mail_de_commentaire@test.com' }
  let!(:commentaire) { create(:commentaire, dossier: dossier, email: email_commentaire, body: 'ma super description') }
  let(:body){'Commentaire de test'}

  before do
    visit "/dossiers/#{dossier_id}/recapitulatif"
  end

  context 'Affichage du flux de commentaire' do
    scenario 'l\'email du contact est présent' do
      expect(page).to have_selector("span[id=email_contact]")
    end

    scenario 'la date du commentaire est présent' do
      expect(page).to have_selector("span[id=created_at]")
    end

    scenario 'le corps du commentaire est présent' do
      expect(page).to have_selector("div[class=description][id=body]")
    end

  end

  context 'Affichage du formulaire de commentaire' do
    scenario 'Le formulaire envoie vers /dossiers/:dossier_id/commentaire en #POST' do
      expect(page).to have_selector("form[action='/dossiers/#{dossier_id}/commentaire'][method=post]")
    end

    scenario 'Champs de texte' do
      expect(page).to have_selector('textarea[id=texte_commentaire][name=texte_commentaire]')
    end

    scenario 'Champs email' do
      expect(page).to have_selector('input[id=email_commentaire][name=email_commentaire]')
    end

    scenario 'Champs email est prérempli' do
      expect(page).to have_content(email_commentaire)
    end
  end
end