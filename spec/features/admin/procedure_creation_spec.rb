require 'features/admin/procedure_spec_helper'

feature 'As an administrateur I wanna create a new procedure', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur, :with_procedure) }

  before do
    login_as administrateur.user, scope: :user
    visit root_path
  end

  context 'Right after sign_in I shall see all procedure states links' do
    scenario 'Finding draft procedures' do
      click_on 'draft-procedures'
      expect(page).to have_current_path(admin_procedures_draft_path)
    end

    scenario 'Finding active procedures' do
      click_on 'active-procedures'
      expect(page).to have_current_path(admin_procedures_path)
    end

    scenario 'Finding archived procedures' do
      click_on 'archived-procedures'
      expect(page).to have_current_path(admin_procedures_archived_path)
    end
  end

  context 'Creating a new procedure' do
    context "when publish_draft enabled" do
      scenario 'Finding save button for new procedure, libelle, description and cadre_juridique required' do
        expect(page).to have_selector('#new-procedure')
        find('#new-procedure').click
        click_on 'from-scratch'

        expect(page).to have_current_path(new_admin_procedure_path)
        expect(find('#procedure_for_individual_true')).to be_checked
        expect(find('#procedure_for_individual_false')).not_to be_checked
        fill_in 'procedure_duree_conservation_dossiers_dans_ds', with: '3'
        fill_in 'procedure_duree_conservation_dossiers_hors_ds', with: '6'
        click_on 'Créer la démarche'

        expect(page).to have_text('Libelle doit être rempli')
        fill_in_dummy_procedure_details
        click_on 'Créer la démarche'

        expect(page).to have_current_path(champs_admin_procedure_path(Procedure.last))
      end
    end
  end

  context 'Editing a new procedure' do
    before 'Create procedure' do
      expect(page).to have_selector('#new-procedure')
      find('#new-procedure').click
      click_on 'from-scratch'

      expect(page).to have_current_path(new_admin_procedure_path)
      fill_in_dummy_procedure_details
      click_on 'Créer la démarche'

      procedure = Procedure.last
      procedure.update(service: create(:service))
    end

    scenario 'Add champ, add file, visualize them in procedure preview' do
      page.refresh
      expect(page).to have_current_path(champs_admin_procedure_path(Procedure.last))

      add_champ(remove_flash_message: true)
      fill_in 'champ-0-libelle', with: 'libelle de champ'
      blur
      expect(page).to have_content('Formulaire enregistré')

      add_champ
      expect(page).to have_selector('#champ-1-libelle')

      click_on Procedure.last.libelle
      find('#publish-procedure-link').click

      preview_window = window_opened_by { click_on 'onglet-preview' }
      within_window(preview_window) do
        expect(page).to have_current_path(apercu_admin_procedure_path(Procedure.last))
        expect(page).to have_field('libelle de champ')
      end
    end

    scenario 'After adding champ and file, make publication' do
      page.refresh

      add_champ(remove_flash_message: true)
      fill_in 'champ-0-libelle', with: 'libelle de champ'
      blur
      expect(page).to have_content('Formulaire enregistré')

      click_on Procedure.last.libelle
      expect(page).to have_current_path(admin_procedure_path(Procedure.last))
      find('#publish-procedure-link').click
      expect(page).to have_content('en test')
      # Only check the path even though the link is the complete URL
      # (Capybara runs the app on an arbitrary host/port.)
      expect(page).to have_link(nil, href: /#{commencer_test_path(Procedure.last.path)}/)

      expect(page).to have_selector('#publish-procedure', visible: true)
      find('#publish-procedure').click

      within '#publish-modal' do
        expect(find_field('procedure_path').value).to eq 'libelle-de-la-procedure'
        fill_in 'lien_site_web', with: 'http://some.website'
        click_on 'publish'
      end

      expect(page).to have_text('Démarche publiée')
      expect(page).to have_selector('.procedure-lien')
    end
  end
end
