require 'spec_helper'

feature 'As a User I want to sort and paginate dossiers', js: true do

  let(:user) { create(:user) }
  let(:procedure_for_individual) { create(:procedure, :published, :for_individual) }

  before "Create dossier" do
    login_as user, scope: :user
    visit commencer_path(procedure_path: procedure_for_individual.path)
    fill_in 'dossier_individual_attributes_nom',       with: 'Nom'
    fill_in 'dossier_individual_attributes_prenom',    with: 'Prenom'
    fill_in 'dossier_individual_attributes_birthdate', with: '14/10/1987'
    find(:css, "#dossier_autorisation_donnees[value='1']").set(true)
    page.find_by_id('etape_suivante').click
    page.find_by_id('suivant').click
    50.times do
      Dossier.create(procedure_id: 1, user_id: 1, state: "initiated")
    end
    visit root_path
  end

  context 'After sign_in, I can see my 51 dossiers on the index' do

    scenario 'Using sort' do
      expect(page.all(:css, '#dossiers_list tr')[1].text.split(" ").first).to eq('1')
      expect(page.all(:css, '#dossiers_list tr')[2].text.split(" ").first).to eq('2')
      visit "/users/dossiers?dossiers_smart_listing[sort][id]=desc"
      expect(page.all(:css, '#dossiers_list tr')[1].text.split(" ").first).to eq('51')
      expect(page.all(:css, '#dossiers_list tr')[2].text.split(" ").first).to eq('50')
      visit "/users/dossiers?dossiers_smart_listing[sort][id]=asc"
      expect(page.all(:css, '#dossiers_list tr')[1].text.split(" ").first).to eq('1')
      expect(page.all(:css, '#dossiers_list tr')[2].text.split(" ").first).to eq('2')
    end

    scenario 'Using pagination' do
      expect(page.all(:css, '#dossiers_list tr')[1].text.split(" ").first).to eq('1')
      page.find('.next_page a').click
      wait_for_ajax
      expect(page.all(:css, '#dossiers_list tr')[1].text.split(" ").first).to eq('8')
      page.find('.next_page a').click
      wait_for_ajax
      expect(page.all(:css, '#dossiers_list tr')[1].text.split(" ").first).to eq('15')
      page.find('.prev a').click
      wait_for_ajax
      page.find('.prev a').click
      wait_for_ajax
      expect(page.all(:css, '#dossiers_list tr')[1].text.split(" ").first).to eq('1')
    end
  end

end
