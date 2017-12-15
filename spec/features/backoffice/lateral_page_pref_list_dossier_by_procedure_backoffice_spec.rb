require 'spec_helper'

feature 'usage of pref list dossier lateral panel by procedure', js: true do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }
  let(:procedure) { create(:procedure, :published, :with_type_de_champ, administrateur: administrateur) }

  before do
    create(:dossier, :with_entreprise, procedure: procedure, state: 'en_construction')
    create :assign_to, procedure: procedure, gestionnaire: gestionnaire

    login_as gestionnaire, scope: :gestionnaire

    visit backoffice_path
  end

  context 'when user enter good credentials' do
    scenario 'he is redirected to /backoffice/dossiers/' do
      expect(page).to have_css('#backoffice-index')
    end

    describe 'user navigate to dossiers list by procedure' do
      before do
        visit backoffice_dossiers_procedure_path(procedure.id)
      end

      scenario 'lateral panel is masked' do
        expect(page).to have_css('#pref-list-menu', visible: false)
      end

      context 'when on click on pref list button' do
        before do
          page.click_on 'pref-list-dossier-open-action'
        end

        scenario 'lateral panel is appeared' do
          wait_for_ajax
          expect(page).to have_css('#pref-list-menu')
        end

        context 'when on click on add attribut specific at the procedure button' do
          before do
            page.click_on 'add_pref_list_champs_' + procedure.types_de_champ.first.id.to_s
          end

          scenario 'preference list panel is brought up to date' do
            wait_for_ajax
            expect(page).to have_css('#delete_pref_list_champs_' + procedure.types_de_champ.first.id.to_s)
          end

          context 'when on click on delete attribut button' do
            before do
              page.click_on 'delete_pref_list_champs_' + procedure.types_de_champ.first.id.to_s
            end

            scenario 'preference list panel is brought up to date' do
              wait_for_ajax
              expect(page).not_to have_css('#delete_pref_list_champs_' + procedure.types_de_champ.first.id.to_s)
            end

            scenario 'dossier is brought up to date' do
              wait_for_ajax
              expect(page).not_to have_selector("a.sortable[data-attr='entreprise.siren']", visible: false)
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
end
