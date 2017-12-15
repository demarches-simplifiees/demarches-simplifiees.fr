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
    page.find_by_id('etape_suivante').trigger('click')
    page.find_by_id('suivant').trigger('click')
    50.times do
      Dossier.create(procedure_id: procedure_for_individual.id, user_id: user.id, state: "en_construction")
    end
    visit root_path
  end

  context 'After sign_in, I can see my 51 dossiers on the index' do
    scenario 'Using sort' do
      visit "/users/dossiers?dossiers_smart_listing[sort][id]=asc"
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq(user.dossiers.first.id.to_s)
      expect(page.all(:css, '#dossiers-list tr')[2].text.split(" ").first).to eq(user.dossiers.second.id.to_s)
      visit "/users/dossiers?dossiers_smart_listing[sort][id]=desc"
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq((user.dossiers.first.id + 50).to_s)
      expect(page.all(:css, '#dossiers-list tr')[2].text.split(" ").first).to eq((user.dossiers.first.id + 49).to_s)
      visit "/users/dossiers?dossiers_smart_listing[sort][id]=asc"
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq(user.dossiers.first.id.to_s)
      expect(page.all(:css, '#dossiers-list tr')[2].text.split(" ").first).to eq(user.dossiers.second.id.to_s)
    end

    scenario 'Using pagination' do
      visit "/users/dossiers?dossiers_smart_listing[sort][id]=asc"
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq(user.dossiers.first.id.to_s)
      page.find('.next_page a').trigger('click')
      wait_for_ajax
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq((user.dossiers.first.id + 10).to_s)
      page.find('.next_page a').trigger('click')
      wait_for_ajax
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq((user.dossiers.first.id + 20).to_s)
      page.find('.prev a').trigger('click')
      wait_for_ajax
      page.find('.prev a').trigger('click')
      wait_for_ajax
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq((user.dossiers.first.id).to_s)
    end
  end
end
