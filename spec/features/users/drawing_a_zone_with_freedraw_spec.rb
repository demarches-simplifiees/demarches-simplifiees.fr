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
      expect(page).to have_css('#login_user')
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
          expect(page).to have_css('#users_index')
        end

        scenario 'alert message is present' do
          expect(page).to have_content('Le status de votre dossier n\'autorise pas cette URL')
        end
      end

      context 'when draw a zone on #map', js: true, vcr: { cassette_name: 'drawing_a_zone_with_freedraw_when_draw_a_zone_on_map' } do
        context 'when module quartiers prioritaires is activated' do
          let(:module_api_carto) { create(:module_api_carto, :with_quartiers_prioritaires) }

          before do
            allow(ModuleApiCartoService).
                to receive(:generate_qp).
                       and_return({"QPCODE1234" => {:code => "QPCODE1234", :nom => "Quartier de test", :commune => "Paris", :geometry => {:type => "MultiPolygon", :coordinates => [[[[2.38715792094576, 48.8723062632126], [2.38724851642619, 48.8721392348061]]]]}}})

            page.execute_script('freeDraw.fire("markers", {latLngs: []});')
            wait_for_ajax
          end

          scenario 'div #map .qp is present' do
            expect(page).to have_css('.content #map.qp')
          end

          scenario 'QP name is present on page' do
            expect(page).to have_content('Quartier de test')
          end

          scenario 'Commune is present on page' do
            expect(page).to have_content('Paris')
          end
        end
      end
    end
  end
end
