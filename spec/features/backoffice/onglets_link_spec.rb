require 'spec_helper'

feature 'on click on tabs button' do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }

  before do
    login_as gestionnaire, scope: :gestionnaire
  end

  context 'when gestionnaire is logged in' do
    context 'when he click on tabs nouveaux' do
      before do
        visit backoffice_dossiers_url(liste: :nouveaux)
        page.click_on 'Nouveaux 0'
      end

      scenario 'it redirect to backoffice dossier termine' do
        expect(page).to have_css('#backoffice_index')
      end
    end

    context 'when he click on tabs a traite' do
      before do
        visit backoffice_dossiers_url(liste: :a_traiter)
        page.click_on 'Action requise 0'
      end

      scenario 'it redirect to backoffice dossier termine' do
        expect(page).to have_css('#backoffice_index')
      end
    end

    context 'when he click on tabs en attente' do
      before do
        visit backoffice_dossiers_url(liste: :en_attente)
        page.click_on 'Attente usager 0'
      end

      scenario 'it redirect to backoffice dossier en attente' do
        expect(page).to have_css('#backoffice_index')
      end
    end

    context 'when he click on tabs a receptionner' do
      before do
        visit backoffice_dossiers_url(liste: :nouveaux)
        page.click_on 'À réceptionner 0'
      end

      scenario 'it redirect to backoffice dossier a_receptionner' do
        expect(page).to have_css('#backoffice_index')
      end
    end

    context 'when he click on tabs a instruire' do
      before do
        visit backoffice_dossiers_url(liste: :a_instruire)
        page.click_on 'À instruire 0'
      end

      scenario 'it redirect to backoffice dossier termine' do
        expect(page).to have_css('#backoffice_index')
      end
    end

    context 'when he click on tabs termine' do
      before do
        visit backoffice_dossiers_url(liste: :termine)
        page.click_on 'Terminé 0'
      end

      scenario 'it redirect to backoffice dossier termine' do
        expect(page).to have_css('#backoffice_index')
      end
    end
  end
end