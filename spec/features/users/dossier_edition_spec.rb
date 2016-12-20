require 'spec_helper'

feature 'As a User I want to edit a dossier I own', js: true do

  let(:user)                     { create(:user) }
  let(:procedure_for_individual) { create(:procedure, :published, :for_individual, :with_api_carto, :with_type_de_champ, :with_two_type_de_piece_justificative) }

  before "Create dossier" do
    login_as user, scope: :user
    visit commencer_path(procedure_path: procedure_for_individual.path)
    fill_in 'dossier_individual_attributes_nom',       with: 'Nom'
    fill_in 'dossier_individual_attributes_prenom',    with: 'Prenom'
    fill_in 'dossier_individual_attributes_birthdate', with: '14/10/1987'
    find(:css, "#dossier_autorisation_donnees[value='1']").set(true)
    page.find_by_id('etape_suivante').click
    page.find_by_id('etape_suivante').click
    page.find_by_id('suivant').click
    visit root_path
  end

  context 'After sign_in, I can navigate through dossiers indexes and edit a dossier' do

    scenario 'After sign_in, I can see dossiers "à traiter" (default), and other indexes' do
      expect(page.find('#a_traiter')['class'] ).to eq('active procedure_list_element')
      page.find_by_id('brouillon').click
      page.find_by_id('a_traiter').click
      page.find_by_id('valides').click
      page.find_by_id('en_instruction').click
      page.find_by_id('termine').click
      page.find_by_id('invite').click
    end

    scenario 'Getting a dossier, I want to create a new message on' do
      page.find_by_id('tr_dossier_' + Dossier.last.id.to_s).click
      expect(page).to have_current_path(users_dossier_recapitulatif_path(Dossier.first.id.to_s), only_path: true)
      page.find_by_id('open-message').click
      page.execute_script("$('#texte_commentaire').data('wysihtml5').editor.setValue('Contenu du nouveau message')")
      page.find_by_id('save-message').click
      expect(page.find('.last-commentaire .content').text).to eq('Contenu du nouveau message')
    end

    scenario 'On the same dossier, I want to edit informations' do
      page.find_by_id('tr_dossier_' + Dossier.last.id.to_s).click
      page.find_by_id('edit-dossier').click
      expect(page).to have_current_path(users_dossier_description_path(Dossier.first.id.to_s), only_path: true)
      fill_in 'champs_1', with: 'Contenu du champ 1'
      page.find_by_id('modification_terminee').click
      expect(page).to have_current_path(users_dossier_recapitulatif_path(Dossier.first.id.to_s), only_path: true)
      expect(page.find('#champ-1-value').text).to eq('Contenu du champ 1')
    end
  end
end
