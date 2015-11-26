require 'spec_helper'

feature 'on click on tabs button' do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateur: administrateur) }

  before do
    login_as gestionnaire, scope: :gestionnaire
  end

  context 'when gestionnaire is logged in' do
    context 'when he click on tabs a traitee' do
      before do
        visit backoffice_dossiers_en_attente_url
        page.click_on 'À traiter 0'
      end

      scenario 'it redirect to backoffice dossier termine' do
        expect(page).to have_css('#backoffice_a_traiter')
      end
    end

    context 'when he click on tabs en attente' do
      before do
        visit backoffice_dossiers_termine_url
        page.click_on 'En attente 0'
      end

      scenario 'it redirect to backoffice dossier en attente' do
        expect(page).to have_css('#backoffice_en_attente')
      end
    end

    context 'when he click on tabs termine' do
      before do
        visit backoffice_dossiers_a_traiter_url
        page.click_on 'Terminé 0'
      end

      scenario 'it redirect to backoffice dossier termine' do
        expect(page).to have_css('#backoffice_termine')
      end
    end
  end
end