require 'spec_helper'

feature 'Carte#Show Page' do
  let (:dossier_id){10000}

  before do
    visit "/dossiers/#{dossier_id}/carte"
  end

  context 'sur la page de la carte d\'une demande' do
    scenario 'le formulaire envoie vers /dossiers/:dossier_id/carte en #POST' do
      expect(page).to have_selector("form[action='/dossiers/#{dossier_id}/carte'][method=post]")
    end

    scenario 'la page des sources CSS de l\'API carto est chargée' do
      expect(page).to have_selector('#sources_CSS_api_carto')
    end

    scenario 'la page des sources JS de l\'API carto est chargée' do
      expect(page).to have_selector('#sources_JS_api_carto')
    end

    scenario 'la carte est bien présente' do
      expect(page).to have_selector('#map_qp');
    end

    context 'présence des inputs hidden' do
      scenario 'stockage de la référence du dossie de l\'API carto' do
        expect(page).to have_selector('input[type=hidden][id=ref_dossier][name=ref_dossier]')
      end

      scenario 'stockage de l\'URL back si elle existe' do
        expect(page).to have_selector('input[type=hidden][id=back_url][name=back_url]')
      end
    end

    context 'si la page précédente n\'est pas recapitulatif' do
      scenario 'le bouton "Etape suivante" est présent' do
        expect(page).to have_selector('#etape_suivante');
      end

      scenario 'le bouton Etape suivante possède un onclick correct' do
        expect(page).to have_selector('input[type=submit][id=etape_suivante][onclick=\'submit_check_draw(event)\']')
      end
    end

    context 'si la page précédente est recapitularif' do
      before do
        visit "/dossiers/#{dossier_id}/carte?back_url=recapitulatif"
      end

      scenario 'le bouton "Etape suivante" n\'est pas présent' do
        expect(page).to_not have_selector('#etape_suivante');
      end

      scenario 'input hidden back_url a pour valeur le params GET' do
        expect(page).to have_selector('input[type=hidden][id=back_url][value=recapitulatif]')
      end

      scenario 'le bouton "Modification terminé" est présent' do
        expect(page).to have_selector('#modification_terminee');
      end

      scenario 'le bouton Etape suivante possède un onclick correct' do
        expect(page).to have_selector('input[type=submit][id=modification_terminee][onclick=\'submit_check_draw(event)\']')
      end

      scenario 'le lien de retour au récapitulatif est présent' do
        expect(page).to have_selector("a[href='/dossiers/#{dossier_id}/recapitulatif']")
      end
    end
  end
end