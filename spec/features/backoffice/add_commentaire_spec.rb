require 'spec_helper'

feature 'add commentaire on backoffice' do
  let(:procedure) { create(:procedure, :published) }
  let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, state: 'en_construction') }
  let(:dossier_id) { dossier.id }
  let!(:commentaire) { create(:commentaire, dossier: dossier, email: 'toto@toto.com') }
  let(:email_commentaire) { 'test@test.com' }
  let(:gestionnaire) { create(:gestionnaire) }
  let(:email_pre_rempli) { 'toto@sgmap.fr' }
  let(:body) { 'Commentaire de test' }

  before do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure
    login_as gestionnaire, scope: :gestionnaire
    visit backoffice_dossier_path(dossier)
  end

  context 'Affichage du formulaire de commentaire' do
    scenario 'Le formulaire envoie vers /dossiers/:dossier_id/commentaire en #POST' do
      expect(page).to have_selector("form[action='/backoffice/commentaires?dossier_id=#{dossier_id}'][method=post]")
    end

    scenario 'Champs de texte' do
      expect(page).to have_selector('textarea[id=texte_commentaire][name=texte_commentaire]')
    end
  end
end
