require 'spec_helper'

feature 'As an Accompagnateur I can navigate and use each functionnality around procedures and their dossiers' do
  let(:user)           { create(:user) }
  let(:gestionnaire)   { create(:gestionnaire) }
  let(:procedure_1)    { create(:procedure, :published, :with_type_de_champ, libelle: 'procedure 1') }
  let(:procedure_2)    { create(:procedure, :published, :with_type_de_champ, libelle: 'procedure 2') }

  before 'Assign procedures to Accompagnateur and generating dossiers for each' do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure_1
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure_2
    30.times do
      Dossier.create(procedure_id: procedure_1.id.to_s, user: user, state: 'en_construction')
    end
    22.times do
      Dossier.create(procedure_id: procedure_2.id.to_s, user: user, state: 'received')
    end
    login_as gestionnaire, scope: :gestionnaire
    visit backoffice_path
  end

  context 'On index' do
    scenario 'Switching between procedures' do
      page.all('#procedure-list a').first.click
      expect(page).to have_current_path(backoffice_dossiers_procedure_path(id: procedure_1.id.to_s), only_path: true)
      expect(page.find('#all_dossiers .count').text).to eq('30 dossiers')
      page.all('#procedure-list a').last.click
      expect(page).to have_current_path(backoffice_dossiers_procedure_path(id: procedure_2.id.to_s), only_path: true)
      expect(page.find('#all_dossiers .count').text).to eq('22 dossiers')
    end

    scenario 'Searching with search bar', js: true do
      page.find_by_id('search-area').trigger('click')
      fill_in 'q', with: (procedure_1.dossiers.first.id + 14)
      page.find_by_id('search-button').click
      page.find_by_id("tr_dossier_#{(procedure_1.dossiers.first.id + 14)}").click
      expect(page).to have_current_path("/backoffice/dossiers/#{(procedure_1.dossiers.first.id + 14)}")
    end

    scenario 'Following dossier' do
      page.all('#procedure-list a').first.click
      expect(page.all('#follow_dossiers .smart-listing')[0]['data-item-count']).to eq ("0")
      page.find_by_id('all_dossiers').click
      expect(page.all('#dossiers-list a').first.text).to eq('Suivre')
      page.all('#dossiers-list a').first.click
      expect(page.all('#follow_dossiers .smart-listing')[0]['data-item-count']).to eq ("1")
    end

    scenario 'Using sort and pagination', js: true do
      visit "/backoffice/dossiers/procedure/#{procedure_1.id}?all_state_dossiers_smart_listing[sort][id]=asc"
      wait_for_ajax
      expect(page.all("#all_state_dossiers .dossier-row")[0]['id']).to eq("tr_dossier_#{procedure_1.dossiers.first.id}")
      visit "/backoffice/dossiers/procedure/#{procedure_1.id}?all_state_dossiers_smart_listing[sort][id]=desc"
      wait_for_ajax
      expect(page.all("#all_dossiers .dossier-row")[0]['id']).to eq("tr_dossier_#{procedure_1.dossiers.last.id}")
      page.find('#all_state_dossiers .next_page a').trigger('click')
      wait_for_ajax
      page.find('#all_state_dossiers .next_page a').trigger('click')
      wait_for_ajax
      expect(page.all("#all_dossiers .dossier-row")[0]['id']).to eq("tr_dossier_#{procedure_1.dossiers.first.id + 9}")
      page.find('#all_state_dossiers .prev a').trigger('click')
      wait_for_ajax
      expect(page.all("#all_dossiers .dossier-row")[0]['id']).to eq("tr_dossier_#{procedure_1.dossiers.first.id + 19}")
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

      visit "/backoffice/dossiers/procedure/#{procedure_1.id}?all_state_dossiers_smart_listing[sort][id]=asc"
      page.find("#all_dossiers #suivre_dossier_#{procedure_1.dossiers.first.id}").click

      visit "/backoffice/dossiers/#{procedure_1.dossiers.second.id}"
      page.find_by_id("suivre_dossier_#{procedure_1.dossiers.second.id}").click

      visit "/backoffice/dossiers/procedure/#{procedure_1.id}"
      expect(page.all('#follow_dossiers .count').first.text).to eq('2 dossiers')
    end

    if ENV['CIRCLECI'].nil?
      scenario 'Adding message', js: true do
        page.find("#all_dossiers #tr_dossier_#{procedure_1.dossiers.first.id}").trigger('click')
        expect(page).to have_current_path(backoffice_dossier_path(procedure_1.dossiers.first.id), only_path: true)
        page.find_by_id('open-message').click
        page.execute_script("$('#texte_commentaire').data('wysihtml5').editor.setValue('Contenu du nouveau message')")
        page.find_by_id('save-message').click
        expect(page.find('.last-commentaire .content').text).to eq('Contenu du nouveau message')
      end
    end
  end
end
