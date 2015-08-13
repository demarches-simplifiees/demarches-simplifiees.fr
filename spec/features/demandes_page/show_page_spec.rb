require 'spec_helper'

feature 'Demandes#Show Page' do
  let(:dossier) { create(:dossier)}
  let (:dossier_id) { dossier.id }

  before do
    visit "/dossiers/#{dossier_id}/demande"
  end

  context 'sur la page de demande d\'un dossier' do
    scenario 'Le formulaire envoie vers /dossiers/:dossier_id/demande en #POST' do
      expect(page).to have_selector("form[action='/dossiers/#{dossier_id}/demande'][method=post]")
    end

    scenario 'la liste des demandes possibles est présente' do
      expect(page).to have_selector ('select[id=ref_formulaire][name=ref_formulaire]');
    end

    scenario 'le bouton "Etape suivante" est présent' do
      expect(page).to have_selector ('#etape_suivante');
    end
  end
end