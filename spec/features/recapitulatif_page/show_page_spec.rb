require 'spec_helper'

feature 'Recapitulatif#Show Page' do
  let(:dossier) { create(:dossier) }
  let(:dossier_id) { dossier.id }

  before do
    Capybara.current_session.driver.header('Referer', '/description')
    visit "/dossiers/#{dossier_id}/recapitulatif"
  end

  context 'sur la page recapitulative' do
    scenario 'la section infos dossier est présente' do
      expect(page).to have_selector('#infos_dossier')
    end

    scenario 'le flux de commentaire est présent' do
      expect(page).to have_selector('#commentaires_flux')
    end

    scenario 'le numéro de dossier est présent' do
      expect(page).to have_selector('#dossier_id')
      expect(page).to have_content(dossier_id)
    end

    context 'les liens de modifications' do
      context 'lien description' do
        scenario 'le lien vers description est présent' do
          expect(page).to have_selector('a[id=modif_description]')
        end

        scenario 'le lien vers description est correct' do
          expect(page).to have_selector("a[id=modif_description][href='/dossiers/#{dossier_id}/description?back_url=recapitulatif']")
        end
      end
    end

    context 'visibilité Félicitation' do
      scenario 'Est affiché quand l\'on vient de la page description hors modification' do
        expect(page).to have_content('Félicitation')
      end

      scenario 'N\'est pas affiché quand l\'on vient d\'une autre la page que description' do
        Capybara.current_session.driver.header('Referer', '/')
        visit "/dossiers/#{dossier_id}/recapitulatif"

        expect(page).to_not have_content('Félicitation')
      end

      scenario 'N\'est pas affiché quand l\'on vient de la page description en modification' do
        Capybara.current_session.driver.header('Referer', '/description?back_url=recapitulatif')
        visit "/dossiers/#{dossier_id}/recapitulatif"

        expect(page).to_not have_content('Félicitation')
      end
    end
  end
end
