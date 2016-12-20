require 'spec_helper'

feature 'As an Accompagnateur I can navigate and use each functionnality around procedures and their dossiers', js: true do

  let(:user)           { create(:user) }
  let(:gestionnaire)   { create(:gestionnaire) }
  let(:procedure_1)    { create(:procedure, :with_type_de_champ, libelle: 'procedure 1') }
  let(:procedure_2)    { create(:procedure, :with_type_de_champ, libelle: 'procedure 2') }

  before 'Assign procedures to Accompagnateur and generating dossiers for each' do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure_1
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure_2
    20.times do
      Dossier.create(procedure_id: procedure_1.id.to_s, user: user, state: 'validated')
    end
    15.times do
      Dossier.create(procedure_id: procedure_2.id.to_s, user: user, state: 'validated')
    end
    login_as gestionnaire, scope: :gestionnaire
    visit backoffice_path
  end

  context 'On index' do

    if false
    scenario 'Switching between procedures' do
      page.all('#procedure_list a').first.click
      expect(page).to have_current_path(backoffice_dossiers_procedure_path(id: procedure_1.id.to_s), only_path: true)
      expect(page.find('#all_dossiers .count').text).to eq('20 dossiers')
      page.all('#procedure_list a').last.click
      expect(page).to have_current_path(backoffice_dossiers_procedure_path(id: procedure_2.id.to_s), only_path: true)
      expect(page.find('#all_dossiers .count').text).to eq('15 dossiers')
      #save_and_open_page
    end

    scenario 'Searching with search bar' do
      page.find_by_id('search_area').trigger('click')
      fill_in 'q', with: '15'
      page.find_by_id('search_button').click
      page.find_by_id('tr_dossier_15').click
      expect(page).to have_current_path("/backoffice/dossiers/15")
    end

    scenario 'Following dossier' do
      page.all('#procedure_list a').first.click
      expect(page.all('#follow_dossiers .smart-listing')[0]['data-item-count']).to eq ("0")
      page.find_by_id('all_dossiers').click
      expect(page.all('#dossiers_list a').first.text).to eq('Suivre')
      page.all('#dossiers_list a').first.click
      expect(page.all('#follow_dossiers .smart-listing')[0]['data-item-count']).to eq ("1")
    end
    end

    scenario 'Using sort' do
    end

    if false
    scenario 'Using pagination' do
    end

    scenario 'Using filter' do
    end

    scenario 'Have an export button' do
    end
    end
  end
end
