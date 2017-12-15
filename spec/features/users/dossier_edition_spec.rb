require 'spec_helper'

feature 'As a User I want to edit a dossier I own' do
  let(:user)                     { create(:user) }
  let(:procedure_for_individual) { create(:procedure, :published, :for_individual, :with_type_de_champ, :with_two_type_de_piece_justificative, :with_dossier_link) }
  let!(:dossier)                 { create(:dossier, :with_entreprise, :for_individual, :with_dossier_link, procedure: procedure_for_individual, user: user, autorisation_donnees: true, state: 'en_construction') }

  before "Create dossier and visit root path" do
    login_as user, scope: :user
    visit root_path
  end

  context 'After sign_in, I can navigate through dossiers indexes and edit a dossier' do
    scenario 'After sign_in, I can see dossiers "à traiter" (default), and other indexes' do
      expect(page.find('#a_traiter')['class'] ).to eq('active procedure-list-element')
      page.find_by_id('brouillon').click
      page.find_by_id('a_traiter').click
      page.find_by_id('en_instruction').click
      page.find_by_id('termine').click
      page.find_by_id('invite').click
    end

    scenario 'Getting a dossier, I want to create a new message on', js: true do
      page.find_by_id('tr_dossier_' + dossier.id.to_s).click
      expect(page).to have_current_path(users_dossier_recapitulatif_path(Dossier.first.id.to_s), only_path: true)
      page.find_by_id('open-message').click
      page.execute_script("$('#texte_commentaire').data('wysihtml5').editor.setValue('Contenu du nouveau message')")
      page.find_by_id('save-message').click
      expect(page.find('.last-commentaire .content').text).to eq('Contenu du nouveau message')
    end

    scenario 'On the same dossier, I want to edit informations', js: true do
      page.find_by_id('tr_dossier_' + dossier.id.to_s).click
      expect(page).to have_current_path(users_dossier_recapitulatif_path(dossier.id.to_s), only_path: true)

      # Linked Dossier
      linked_dossier_id = dossier.champs.find { |c| c.type_de_champ.type_champ == 'dossier_link' }.value
      expect(page).to have_link("Dossier #{linked_dossier_id}")

      page.find_by_id('maj_infos').trigger('click')
      expect(page).to have_current_path(users_dossier_description_path(dossier.id.to_s), only_path: true)
      champ_id = dossier.champs.find { |t| t.type_champ == "text" }.id
      fill_in "champs_#{champ_id.to_s}", with: 'Contenu du champ 1'
      page.find_by_id('modification_terminee').click
      expect(page).to have_current_path(users_dossier_recapitulatif_path(dossier.id.to_s), only_path: true)
      expect(page.find("#champ-#{champ_id}-value").text).to eq('Contenu du champ 1')
    end
  end
end
