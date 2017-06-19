require 'spec_helper'

feature 'drawing a zone with freedraw' do
  let(:user) { create(:user) }
  let(:module_api_carto) { create(:module_api_carto, :with_api_carto) }
  let(:procedure) { create(:procedure, module_api_carto: module_api_carto) }
  let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, user: user) }

  context 'when user is not logged in' do
    before do
      visit users_dossier_carte_path dossier_id: dossier.id
    end

    scenario 'he is redirected to login page' do
      expect(page).to have_css('#new_user')
    end

    scenario 'he logs in and he is redirected to carte page', vcr: { cassette_name: 'drawing_a_zone_with_freedraw_redirected_to_carte_page' } do
      within('#new_user') do
        page.find_by_id('user_email').set user.email
        page.find_by_id('user_password').set user.password
        page.click_on 'Se connecter'
      end
      expect(page).to have_css('.content #map')
    end
  end

  context 'when user is logged in' do
    before do
      login_as user, scope: :user
    end

    context 'when he is visiting the map page' do
      before do
        visit users_dossier_carte_path dossier_id: dossier.id
      end

      context 'when procedure have api carto activated' do
        scenario 'he is redirected to carte page', vcr: { cassette_name: 'drawing_a_zone_with_freedraw_redirected_to_carte_page' } do
          expect(page).to have_css('.content #map')
        end
      end

      context 'when procedure does not have api carto activated' do
        let(:module_api_carto) { create(:module_api_carto) }

        scenario 'he is redirect to user dossiers index' do
          expect(page).to have_css('#users-index')
        end

        scenario 'alert message is present' do
          expect(page).to have_content('Le status de votre dossier n\'autorise pas cette URL')
        end
      end
    end
  end
end
