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
      page.all('.tabs li a')[1].click
      expect(page).to have_current_path(admin_procedures_path(statut: 'brouillons'))
    end

    scenario 'Finding active procedures' do
      page.all('.tabs li a').first.click
      expect(page).to have_current_path(admin_procedures_path(statut: 'publiees'))
    end

    scenario 'Finding archived procedures' do
      page.all('.tabs li a').last.click
      expect(page).to have_current_path(admin_procedures_path(statut: 'archivees'))
    end
  end

  context 'Creating a new procedure' do
    context "when publish_draft enabled" do
      scenario 'Finding save button for new procedure, libelle, description and cadre_juridique required' do
        expect(page).to have_selector('#new-procedure')
        find('#new-procedure').click

        expect(page).to have_current_path(new_from_existing_admin_procedures_path)
        click_on 'Créer une nouvelle démarche de zéro'
        expect(find('#procedure_for_individual_true')).to be_checked
        expect(find('#procedure_for_individual_false')).not_to be_checked
        fill_in 'procedure_duree_conservation_dossiers_dans_ds', with: '3'
        click_on 'Créer la démarche'

        expect(page).to have_text('Toutes les cases concernant le RGPD et le RGS doivent être cochées')
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

      expect(page).to have_current_path(new_from_existing_admin_procedures_path)
      click_on 'Créer une nouvelle démarche de zéro'
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

      find('#preview-procedure').click

      expect(page).to have_current_path(apercu_admin_procedure_path(Procedure.last))
      expect(page).to have_field('libelle de champ')
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

      expect(page).to have_selector('#procedure_path', visible: true)
      expect(find_field('procedure_path').value).to eq 'service-libelle-de-la-procedure'
      fill_in 'lien_site_web', with: 'http://some.website'
      click_on 'publish'

      expect(page).to have_text('Démarche publiée')
    end
  end
end
