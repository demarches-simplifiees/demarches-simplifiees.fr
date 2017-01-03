require 'spec_helper'

feature 'As a User I want to edit a dossier I own', js: true do

  let(:user)                     { create(:user) }
  let(:procedure_for_individual) { create(:procedure, :published, :for_individual, :with_api_carto, :with_type_de_champ, :with_two_type_de_piece_justificative) }
  let!(:dossier)                 { create(:dossier, :with_entreprise, procedure: procedure_for_individual, user: user, state: 'initiated') }

  before "Create dossier and visit root path" do
    login_as user, scope: :user
    visit root_path
  end

  context 'After sign_in, I can navigate through dossiers indexes and edit a dossier' do

    scenario 'After sign_in, I can see dossiers "à traiter" (default), and other indexes' do
      expect(page.find('#a_traiter')['class'] ).to eq('active procedure_list_element')
      page.find_by_id('brouillon').trigger('click')
      page.find_by_id('a_traiter').trigger('click')
      page.find_by_id('valides').trigger('click')
      page.find_by_id('en_instruction').trigger('click')
      page.find_by_id('termine').trigger('click')
      page.find_by_id('invite').trigger('click')
    end

    scenario 'Getting a dossier, I want to create a new message on' do
      page.find_by_id('tr_dossier_' + Dossier.last.id.to_s).trigger('click')
      expect(page).to have_current_path(users_dossier_recapitulatif_path(Dossier.first.id.to_s), only_path: true)
      page.find_by_id('open-message').trigger('click')
      page.execute_script("$('#texte_commentaire').data('wysihtml5').editor.setValue('Contenu du nouveau message')")
      page.find_by_id('save-message').trigger('click')
      expect(page.find('.last-commentaire .content').text).to eq('Contenu du nouveau message')
    end

    scenario 'On the same dossier, I want to edit informations' do
      page.find_by_id('tr_dossier_' + Dossier.last.id.to_s).trigger('click')
      page.find_by_id('edit-dossier').trigger('click')
      expect(page).to have_current_path(users_dossier_description_path(Dossier.first.id.to_s), only_path: true)
      fill_in 'champs_1', with: 'Contenu du champ 1'
      page.find_by_id('modification_terminee').trigger('click')
      expect(page).to have_current_path(users_dossier_recapitulatif_path(Dossier.first.id.to_s), only_path: true)
      expect(page.find('#champ-1-value').text).to eq('Contenu du champ 1')
    end
  end
end
