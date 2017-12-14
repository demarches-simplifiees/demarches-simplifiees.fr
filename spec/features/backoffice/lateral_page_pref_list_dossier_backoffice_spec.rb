require 'spec_helper'

feature 'usage of pref list dossier lateral panel', js: true do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }
  let(:procedure) { create(:procedure, :published, administrateur: administrateur) }

  before do
    create(:dossier, :with_entreprise, procedure: procedure, state: 'en_construction')
    create :assign_to, procedure: procedure, gestionnaire: gestionnaire

    login_as gestionnaire, scope: :gestionnaire

    visit backoffice_path
  end

  context 'when user enter good credentials' do
    scenario 'he is redirected to /backoffice' do
      expect(page).to have_css('#backoffice-index')
    end

    scenario 'lateral panel is masked' do
      expect(page).to have_css('#pref-list-menu', visible: false)
    end

    context 'when on click on pref list button' do
      before do
        page.click_on 'pref-list-dossier-open-action'
      end

      scenario 'lateral panel is appeared' do
        expect(page).to have_css('#pref-list-menu')
      end

      context 'when on click on add attribut button' do
        before do
          page.click_on 'add_pref_list_entreprise_siren'
        end

        scenario 'preference list panel is brought up to date' do
          wait_for_ajax
          expect(page).to have_css('#delete_pref_list_entreprise_siren')
        end

        scenario 'dossier is brought up to date' do
          wait_for_ajax
          expect(page).to have_selector("a.sortable[data-attr='entreprise.siren']", visible: false)
        end

        context 'when on click on delete attribut button' do
          before do
            page.click_on 'delete_pref_list_entreprise_siren'
          end

          scenario 'preference list panel is brought up to date' do
            wait_for_ajax
            expect(page).not_to have_css('#delete_pref_list_entreprise_siren')
          end

          scenario 'dossier is brought up to date', js: true do
            wait_for_ajax
            expect(page).not_to have_selector("a.sortable[data-attr='entreprise.siren']", visible: true)
          end

          context 'when on click on close pref list button' do
            before do
              page.click_on 'pref-list-dossier-close-action'
            end

            scenario 'lateral panel is masked' do
              wait_for_ajax
              expect(page).to have_css('#pref-list-menu', visible: false)
            end
          end
        end
      end
    end
  end
end
