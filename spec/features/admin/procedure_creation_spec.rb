require 'spec_helper'
require 'features/admin/procedure_spec_helper'

feature 'As an administrateur I wanna create a new procedure', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur) }

  before do
    Flipflop::FeatureSet.current.test!.switch!(:test_procedure, true)
  end

  before do
    login_as administrateur, scope: :administrateur
    visit root_path
  end

  context 'Right after sign_in I shall see all procedure states links' do
    scenario 'Finding draft procedures' do
      page.find_by_id('draft-procedures').click
      expect(page).to have_current_path(admin_procedures_draft_path)
    end

    scenario 'Finding testing procedures' do
      page.find_by_id('testing-procedures').click
      expect(page).to have_current_path(admin_procedures_testing_path)
    end

    scenario 'Finding active procedures' do
      page.find_by_id('active-procedures').click
      expect(page).to have_current_path(admin_procedures_path)
    end

    scenario 'Finding archived procedures' do
      page.find_by_id('archived-procedures').click
      expect(page).to have_current_path(admin_procedures_archived_path)
    end
  end

  context 'Creating a new procedure' do
    scenario 'Finding new procedure link' do
      page.find_by_id('new-procedure').click
      page.find_by_id('from-scratch').click
      expect(page).to have_current_path(new_admin_procedure_path)
    end

    scenario 'Finding save button for new procedure, libelle, description and cadre_juridique required' do
      page.find_by_id('new-procedure').click
      page.find_by_id('from-scratch').click
      fill_in 'procedure_duree_conservation_dossiers_dans_ds', with: '3'
      fill_in 'procedure_duree_conservation_dossiers_hors_ds', with: '6'
      page.find_by_id('save-procedure').click
      page.find_by_id('flash_message').visible?
      fill_in_dummy_procedure_details
      page.find_by_id('save-procedure').click
      expect(page).to have_current_path(admin_procedure_types_de_champ_path(Procedure.first.id.to_s))
    end
  end

  context 'Editing a new procedure' do
    before 'Create procedure' do
      page.find_by_id('new-procedure').click
      page.find_by_id('from-scratch').click
      fill_in_dummy_procedure_details
      page.find_by_id('save-procedure').click

      procedure = Procedure.last
      procedure.update(service: create(:service))
    end

    scenario 'Add champ, add file, visualize them in procedure preview' do
      page.find_by_id('procedure_types_de_champ_attributes_0_libelle').set 'libelle de champ'
      page.find_by_id('add_type_de_champ').click
      page.find_by_id('procedure_types_de_champ_attributes_1_libelle')
      expect(Procedure.first.types_de_champ.first.libelle).to eq('libelle de champ')

      page.find_by_id('onglet-pieces').click
      expect(page).to have_current_path(admin_procedure_pieces_justificatives_path(Procedure.first.id.to_s))
      page.find_by_id('procedure_types_de_piece_justificative_attributes_0_libelle').set 'libelle de piece'
      page.find_by_id('add_piece_justificative').click
      page.find_by_id('procedure_types_de_piece_justificative_attributes_1_libelle')

      preview_window = window_opened_by { page.find_by_id('onglet-preview').click }
      within_window(preview_window) do
        expect(page).to have_current_path(apercu_procedure_path(Procedure.first))
        expect(page.find("input[type='text']")['placeholder']).to eq('libelle de champ')
        expect(page.first('.pj-input label').text).to eq('libelle de piece')
      end
    end

    scenario 'After adding champ and file, check impossibility to publish procedure, add accompagnateur and make publication' do
      page.find_by_id('procedure_types_de_champ_attributes_0_libelle').set 'libelle de champ'
      page.find_by_id('add_type_de_champ').click
      page.find_by_id('onglet-pieces').click
      page.find_by_id('procedure_types_de_piece_justificative_attributes_0_libelle').set 'libelle de piece'
      page.find_by_id('add_piece_justificative').click

      page.find_by_id('onglet-infos').click
      expect(page).to have_current_path(admin_procedure_path(Procedure.first.id.to_s))
      expect(page.find_by_id('test-procedure')['disabled']).to eq('true')

      page.find_by_id('onglet-accompagnateurs').click
      expect(page).to have_current_path(admin_procedure_accompagnateurs_path(Procedure.first.id.to_s))
      page.find_by_id('gestionnaire_email').set 'gestionnaire@apientreprise.fr'
      page.find_by_id('add-gestionnaire-email').click
      page.first('.gestionnaire-affectation').click

      page.find_by_id('onglet-infos').click
      expect(page).to have_selector('#test-procedure', visible: true)
      page.find_by_id('test-procedure').click

      expect(page.find_by_id('procedure_path')['value']).to eq('libelle-de-la-procedure')
      page.find_by_id('publish').click
      expect(page).to have_current_path(admin_procedures_testing_path)

      page.find('tr[data-dossier_url]').click
      expect(page).to have_current_path(admin_procedure_path(Procedure.first.id.to_s))
      page.find_by_id('publish-procedure').click
      expect(page.find_by_id('procedure_path')['value']).to eq('libelle-de-la-procedure')
      page.find_by_id('publish').click
      expect(page).to have_current_path(admin_procedures_path)
    end
  end
end
