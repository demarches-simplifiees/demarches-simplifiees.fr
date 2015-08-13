require 'spec_helper'

feature 'Dossier#Show Page' do
  let(:dossier) { create(:dossier, :with_entreprise) }

  let(:dossier_id) { dossier.id }

  before do
    visit "/dossiers/#{dossier_id}"
  end

  context 'sur la page d\'information d\'un SIRET' do
    scenario 'Le formulaire envoie vers /dossiers/:dossier_id en #POST' do
      expect(page).to have_selector("form[action='/dossiers/#{dossier_id}'][method=post]")
    end

    scenario 'la checkbox d\'information est présente' do
      expect(page).to have_selector('input[type=checkbox][id=autorisation_donnees][name=autorisation_donnees]')
    end

    scenario 'la checkbox est décochée par défault' do
      expect(page).to_not have_selector('input[type=checkbox][id=autorisation_donnees][name=autorisation_donnees][value=on]')
    end

    scenario 'le texte d\'information des droits est correct' do
      expect(page).to have_content ("J'autorise les organismes publics à vérifier les informations de mon entreprise auprès des administrations concernées. Ces informations resteront strictement confidentielles.")
    end

    scenario 'les informations de l\'entreprise sont présents' do
      expect(page).to have_content ('SIRET');
    end

    scenario 'le bouton "Etape suivante" est présent' do
      expect(page).to have_selector ('#etape_suivante');
    end
  end
end