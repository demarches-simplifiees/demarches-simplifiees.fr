require 'spec_helper'

feature 'Description#Show Page' do
  let (:dossier_id){10000}

  before do
    visit "/dossiers/#{dossier_id}/description"
  end

  context 'tous les attributs sont présents sur la page' do
    scenario 'Le formulaire envoie vers /dossiers/:dossier_id/description en #POST' do
      expect(page).to have_selector("form[action='/dossiers/#{dossier_id}/description'][method=post]")
    end

    scenario 'Nom du projet' do
      expect(page).to have_selector('input[id=nom_projet][name=nom_projet]')
    end

    scenario 'Description du projet' do
      expect(page).to have_selector('textarea[id=description][name=description]')
    end

    scenario 'Montant du projet' do
      expect(page).to have_selector('input[id=montant_projet][name=montant_projet]')
    end

    scenario 'Montant du projet est de type number' do
      expect(page).to have_selector('input[type=number][id=montant_projet]')
    end

    scenario 'Montant des aides du projet' do
      expect(page).to have_selector('input[id=montant_aide_demande][name=montant_aide_demande]')
    end

    scenario 'Montant des aides du projet est de type number' do
      expect(page).to have_selector('input[type=number][id=montant_aide_demande]')
    end

    scenario 'Date prévisionnelle du projet' do
      expect(page).to have_selector('input[id=date_previsionnelle][name=date_previsionnelle]')
    end

    scenario 'Date prévisionnelle du projet est de type text avec un data-provide=datepicker' do
      expect(page).to have_selector('input[type=text][id=date_previsionnelle][data-provide=datepicker]')
    end

    scenario 'Mail de contact' do
      expect(page).to have_selector('input[id=mail_contact][name=mail_contact]')
    end

    scenario 'Mail de contact est de type mail' do
      expect(page).to have_selector('input[type=email][id=mail_contact]')
    end

    scenario 'Charger un dossier pdf' do
      expect(page).to have_selector('input[id=dossier_pdf][name=dossier_pdf]')
    end

    scenario 'Charger un dossier pdf est de type file' do
      expect(page).to have_selector('input[type=file][id=dossier_pdf]')
    end
  end

  context 'si la page précédente n\'est pas recapitulatif' do
    scenario 'le bouton "Terminer" est présent' do
      expect(page).to have_selector('#suivant');
    end
  end

  context 'si la page précédente est recapitularif' do
    before do
      visit "/dossiers/#{dossier_id}/description?back_url=recapitulatif"
    end

    scenario 'le bouton "Terminer" n\'est pas présent' do
      expect(page).to_not have_selector('#suivant');
    end

    scenario 'input hidden back_url a pour valeur le params GET' do
      expect(page).to have_selector('input[type=hidden][id=back_url][value=recapitulatif]')
    end

    scenario 'le bouton "Modification terminé" est présent' do
      expect(page).to have_selector('#modification_terminee');
    end

    scenario 'le lien de retour au récapitulatif est présent' do
      expect(page).to have_selector("a[href='/dossiers/#{dossier_id}/recapitulatif']")
    end
  end

  context 'les valeurs sont réaffichées si elles sont présentes dans la BDD' do
    let(:nom_projet){'Projet de test'}
    let(:description){'Description de test.'}
    let(:montant_projet){12000}
    let(:montant_aide_demande){3000}
    let(:date_previsionnelle){'20/01/2016'}
    let(:mail_contact){'test@test.com'}

    scenario 'Nom du projet' do
      expect(page).to have_selector("input[id=nom_projet][value='#{nom_projet}']")
    end

    scenario 'Description du projet' do
      expect(page).to have_content("#{description}")
    end

    scenario 'Montant du projet' do
      expect(page).to have_selector("input[id=montant_projet][value='#{montant_projet}']")
    end

    scenario 'Montant des aides du projet' do
      expect(page).to have_selector("input[id=montant_aide_demande][value='#{montant_aide_demande}']")
    end

    scenario 'Date prévisionnelle du projet' do
      expect(page).to have_selector("input[id=date_previsionnelle][value='#{date_previsionnelle}']")
    end

    scenario 'Mail de contact' do
      expect(page).to have_selector("input[id=mail_contact][value='#{mail_contact}']")
    end
  end
end