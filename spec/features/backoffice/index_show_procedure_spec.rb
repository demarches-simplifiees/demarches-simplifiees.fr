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

    scenario 'Switching between procedures' do
      page.all('#procedure_list a').first.trigger('click')
      expect(page).to have_current_path(backoffice_dossiers_procedure_path(id: procedure_1.id.to_s), only_path: true)
      expect(page.find('#all_dossiers .count').text).to eq('20 dossiers')
      page.all('#procedure_list a').last.trigger('click')
      expect(page).to have_current_path(backoffice_dossiers_procedure_path(id: procedure_2.id.to_s), only_path: true)
      expect(page.find('#all_dossiers .count').text).to eq('15 dossiers')
    end

    scenario 'Searching with search bar' do
      page.find_by_id('search_area').trigger('click')
      fill_in 'q', with: '15'
      page.find_by_id('search_button').trigger('click')
      page.find_by_id('tr_dossier_15').trigger('click')
      expect(page).to have_current_path("/backoffice/dossiers/15")
    end

    scenario 'Following dossier' do
      page.all('#procedure_list a').first.trigger('click')
      expect(page.all('#follow_dossiers .smart-listing')[0]['data-item-count']).to eq ("0")
      page.find_by_id('all_dossiers').trigger('click')
      expect(page.all('#dossiers_list a').first.text).to eq('Suivre')
      page.all('#dossiers_list a').first.trigger('click')
      expect(page.all('#follow_dossiers .smart-listing')[0]['data-item-count']).to eq ("1")
    end

    scenario 'Using sort and pagination' do
      visit "/backoffice/dossiers/procedure/1?all_state_dossiers_smart_listing[sort][id]=asc"
      wait_for_ajax
      expect(page.all("#all_state_dossiers .dossier-row")[0]['id']).to eq('tr_dossier_1')
      visit "/backoffice/dossiers/procedure/1?all_state_dossiers_smart_listing[sort][id]=desc"
      wait_for_ajax
      expect(page.all(".dossier-row")[0]['id']).to eq('tr_dossier_20')
      page.find('#all_state_dossiers .next_page a').trigger('click')
      wait_for_ajax
      page.find('#all_state_dossiers .next_page a').trigger('click')
      wait_for_ajax
      expect(page.all(".dossier-row")[0]['id']).to eq('tr_dossier_6')
      page.find('#all_state_dossiers .prev a').trigger('click')
      wait_for_ajax
      expect(page.all(".dossier-row")[0]['id']).to eq('tr_dossier_13')
    end

    scenario 'Using filter' do
    end

    scenario 'Have an export button' do
      expect(page.all('.export-link')[0].text).to eq('Au format CSV')
      expect(page.all('.export-link')[1].text).to eq('Au format XLSX')
      expect(page.all('.export-link')[2].text).to eq('Au format ODS')
    end
  end

  context 'On show' do

    scenario 'Following dossier' do
      expect(page.all('#follow_dossiers .count').first.text).to eq('0 dossiers')
      visit "/backoffice/dossiers/procedure/1?all_state_dossiers_smart_listing[sort][id]=asc"
      page.find_by_id("suivre_dossier_1").trigger('click')
      visit "backoffice/dossiers/4"
      page.find_by_id("suivre_dossier_4").trigger('click')
      visit "/backoffice/dossiers/procedure/1"
      expect(page.all('#follow_dossiers .count').first.text).to eq('2 dossiers')
    end

    scenario 'Adding message' do
      page.find_by_id('tr_dossier_4').trigger('click')
      expect(page).to have_current_path(backoffice_dossier_path(4), only_path: true)
      page.find_by_id('open-message').trigger('click')
      page.execute_script("$('#texte_commentaire').data('wysihtml5').editor.setValue('Contenu du nouveau message')")
      page.find_by_id('save-message').trigger('click')
      expect(page.find('.last-commentaire .content').text).to eq('Contenu du nouveau message')
    end
  end
end
