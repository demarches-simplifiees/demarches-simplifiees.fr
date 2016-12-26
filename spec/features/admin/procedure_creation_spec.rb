require 'spec_helper'

feature 'As an administrateur I wanna create a new procedure', js: true do

  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
    visit root_path
  end

  context 'Right after sign_in I shall see all procedure states links' do

    scenario 'Finding draft procedures' do
      page.find_by_id('draft-procedures').click
      expect(page).to have_current_path(admin_procedures_draft_path, only_path: true)
    end

    scenario 'Finding active procedures' do
      page.find_by_id('active-procedures').click
      expect(page).to have_current_path(admin_procedures_path, only_path: true)
    end

    scenario 'Finding archived procedures' do
      page.find_by_id('archived-procedures').click
      expect(page).to have_current_path(admin_procedures_archived_path, only_path: true)
    end
  end

  context 'Creating a new procedure' do

    scenario 'Finding new procedure link' do
      page.find_by_id('new-procedure').click
      expect(page).to have_current_path(new_admin_procedure_path, only_path: true)
    end

    scenario 'Finding save button for new procedure, libelle and description required' do
      page.find_by_id('new-procedure').click
      page.find_by_id('save-procedure').click
      page.find_by_id('flash_message').visible?
      fill_in 'procedure_libelle', with: 'libelle de la procedure'
      page.execute_script("$('#procedure_description').data('wysihtml5').editor.setValue('description de la procedure')")
      page.find_by_id('save-procedure').click
      expect(page).to have_current_path(admin_procedure_types_de_champ_path(Procedure.first.id.to_s))
    end
  end

  context 'Editing a new procedure' do

    before 'Create procedure' do
      page.find_by_id('new-procedure').click
      fill_in 'procedure_libelle', with: 'libelle de la procedure'
      page.execute_script("$('#procedure_description').data('wysihtml5').editor.setValue('description de la procedure')")
      page.find_by_id('save-procedure').click
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

      page.find_by_id('onglet-preview').click
      expect(page).to have_current_path(admin_procedure_previsualisation_path(Procedure.first.id.to_s))
      expect(page.find_by_id('champs_1')['placeholder']).to eq('libelle de champ')
      expect(page.first('.piece-libelle').text).to eq('libelle de piece')
    end

    scenario 'After adding champ and file, check impossibility to publish procedure, add accompagnateur and make publication' do
      page.find_by_id('procedure_types_de_champ_attributes_0_libelle').set 'libelle de champ'
      page.find_by_id('add_type_de_champ').click
      page.find_by_id('onglet-pieces').click
      page.find_by_id('procedure_types_de_piece_justificative_attributes_0_libelle').set 'libelle de piece'
      page.find_by_id('add_piece_justificative').click

      page.find_by_id('onglet-infos').click
      expect(page).to have_current_path(admin_procedure_path(Procedure.first.id.to_s))
      expect(page.find_by_id('publish-procedure')['disabled']).to eq('disabled')

      page.find_by_id('onglet-accompagnateurs').click
      expect(page).to have_current_path(admin_procedure_accompagnateurs_path(Procedure.first.id.to_s))
      page.find_by_id('gestionnaire_email').set 'gestionnaire@apientreprise.fr'
      page.find_by_id('add-gestionnaire-email').click
      page.first('.gestionnaire-affectation').click

      page.find_by_id('onglet-infos').click
      expect(page).to have_selector('#publish-procedure', visible: true)
      page.find_by_id('publish-procedure').click

      expect(page.find_by_id('procedure_path')['value']).to eq('libelle_de_la_procedure')
      page.find_by_id('publish').click
      expect(page).to have_selector('.procedure-lien')
    end
  end
end
