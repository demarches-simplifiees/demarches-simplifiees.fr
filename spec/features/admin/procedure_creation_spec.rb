require 'spec_helper'
require 'features/admin/procedure_spec_helper'

feature 'As an administrateur I wanna create a new procedure', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur, :with_procedure) }

  before do
    login_as administrateur, scope: :administrateur
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
        fill_in 'procedure_duree_conservation_dossiers_dans_ds', with: '3'
        fill_in 'procedure_duree_conservation_dossiers_hors_ds', with: '6'
        click_on 'save-procedure'

        expect(page).to have_text('Toutes les cases concernant le RGPD et le RGS doivent être cochées')
        fill_in_dummy_procedure_details
        click_on 'save-procedure'

        expect(page).to have_current_path(champs_procedure_path(Procedure.last))
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
      click_on 'save-procedure'

      procedure = Procedure.last
      procedure.update(service: create(:service))
    end

    context 'With old PJ' do
      before do
        # Create a dummy PJ, because adding PJs is no longer allowed on procedures that
        # do not already have one
        Procedure.last.types_de_piece_justificative.create(libelle: "dummy PJ")
      end

      scenario 'Add champ, add file, visualize them in procedure preview' do
        page.refresh
        expect(page).to have_current_path(champs_procedure_path(Procedure.last))

        expect(page).to have_selector('#champ-0-libelle')
        fill_in 'champ-0-libelle', with: 'libelle de champ'
        blur
        expect(page).to have_content('Formulaire enregistré')

        within '.buttons' do
          click_on 'Ajouter un champ'
        end
        expect(page).to have_selector('#champ-1-libelle')

        click_on Procedure.last.libelle
        click_on 'onglet-pieces'
        expect(page).to have_current_path(admin_procedure_pieces_justificatives_path(Procedure.last))
        fill_in 'procedure_types_de_piece_justificative_attributes_0_libelle', with: 'libelle de piece'
        click_on 'add_piece_justificative'
        expect(page).to have_current_path(admin_procedure_pieces_justificatives_path(Procedure.last))
        expect(page).to have_selector('#procedure_types_de_piece_justificative_attributes_1_libelle')

        preview_window = window_opened_by { click_on 'onglet-preview' }
        within_window(preview_window) do
          expect(page).to have_current_path(apercu_procedure_path(Procedure.last))
          expect(page).to have_field('libelle de champ')
          expect(page).to have_field('libelle de piece')
        end
      end

      scenario 'After adding champ and file, make publication' do
        page.refresh

        fill_in 'champ-0-libelle', with: 'libelle de champ'
        blur
        expect(page).to have_content('Formulaire enregistré')

        click_on Procedure.last.libelle
        click_on 'onglet-pieces'

        expect(page).to have_current_path(admin_procedure_pieces_justificatives_path(Procedure.last))
        fill_in 'procedure_types_de_piece_justificative_attributes_0_libelle', with: 'libelle de piece'
        click_on 'add_piece_justificative'

        click_on 'onglet-infos'
        expect(page).to have_current_path(admin_procedure_path(Procedure.last))
        expect(page).to have_selector('#publish-procedure', visible: true)
        find('#publish-procedure').click

        within '#publish-modal' do
          expect(page).to have_field('procedure_path')
          click_on 'publish'
        end

        expect(page).to have_text('Démarche publiée')
        expect(page).to have_selector('.procedure-lien')
      end
    end
  end
end
